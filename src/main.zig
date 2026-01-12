const std = @import("std");
const builtin = @import("builtin");

const build = @import("build.zig.zon");

const configuration = @import("configuration/configuration.zig");

const AllocatorTracer = @import("commons/allocator.zig").AllocatorTracer;
const MiniLCG = @import("commons/mini_lcg.zig").MiniLCG;

const console = @import("io/console.zig");
const Printer = @import("io/printer.zig").Printer;
const MatrixPrinter = @import("io/matrix_printer.zig").MatrixPrinter;

const ascii = @import("domain/ascii.zig");
const color = @import("domain/color.zig");
const matrix = @import("domain/matrix.zig");

var exit_requested: bool = false;

pub fn main() !void {
    try console.enableANSI();

    var basePersistentAllocator = std.heap.page_allocator;
    var persistentAllocator = AllocatorTracer.init(&basePersistentAllocator);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var baseScratchAllocator = gpa.allocator();
    var scratchAllocator = AllocatorTracer.init(&baseScratchAllocator);

    var arena = std.heap.ArenaAllocator.init(scratchAllocator.allocator());
    defer arena.deinit();

    var printer = Printer{ .arena = &arena, .out = std.fs.File.stdout() };
    defer printer.reset();

    const config = try configuration.fromArgs(persistentAllocator.allocator(), &printer);

    try run(&persistentAllocator, &scratchAllocator, &config, &printer);
}

pub fn run(persistentAllocator: *AllocatorTracer, scratchAllocator: *AllocatorTracer, config: *const configuration.Configuration, printer: *Printer) !void {
    try defineSignalHandlers();

    var allocator = persistentAllocator.allocator();

    var lcg = MiniLCG.init(config.seed);

    var asciiGenerator = ascii.AsciiGenerator.init(&lcg, config.asciiMode);
    var scale = try color.ColorScale.init(&allocator, config.dropLen, color.rgbOf(config.rainColor), config.rainMode);
    var matrixPrinter = MatrixPrinter.init(&allocator, printer, config.formatter, &scale);

    while (!exit_requested) {
        const winsize = try console.winSize();

        // Tested on Windows CMD.
        var space: usize = 0;
        if (config.debug) {
            space += 4;
        }

        const area = winsize.cols * winsize.rows;

        const cols = winsize.cols;
        const rows = winsize.rows - space;
        const fixedArea = rows * cols;

        var mtrx = matrix.Matrix.init(&allocator, &lcg, &asciiGenerator, &scale, config.matrixMode);
        try mtrx.build(cols, rows);

        try printer.print(console.CLEAN_CONSOLE);
        try printer.print(console.HIDE_CURSOR);

        var persistentBytes = persistentAllocator.bytes();
        var scratchBytes = scratchAllocator.bytes();

        try printer.print("\x1b[?1049h");

        while (!exit_requested) {
            try printer.print(console.RESET_CURSOR);
            if (config.debug) {
                try printer.printf("{}: {s}\n", .{ build.name, build.version });
                try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes\n", .{ persistentBytes, scratchBytes });
                try printer.printf("Speed: {d}ms | Ascii Mode: {any} | Rain color: {any} | Matrix Mode: {any} | Formatter mode: {any}\n", .{ config.milliseconds, config.asciiMode, config.rainColor, config.matrixMode, config.formatter.code() });
                try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Drop lenght: {d}\n", .{ config.seed, fixedArea, cols, rows, config.dropLen });
            }
            try matrixPrinter.print(space, &mtrx);
            try mtrx.next();
            std.Thread.sleep(config.milliseconds * std.time.ns_per_ms);

            persistentBytes = persistentAllocator.bytes();
            scratchBytes = scratchAllocator.bytes();

            printer.reset();

            const newWinsize = try console.winSize();
            if (area != newWinsize.cols * newWinsize.rows) {
                break;
            }
        }

        try printer.print("\x1b[?1049l");

        try printer.print(console.CLEAN_CONSOLE);

        mtrx.free();
    }

    scale.free();
    printer.reset();

    try printer.print(console.CLEAN_CONSOLE);
    try printer.print("\n");

    try printer.print(console.SHOW_CURSOR);
    try printer.print(console.RESET_CURSOR);
}

pub fn defineSignalHandlers() !void {
    if (builtin.os.tag == .windows) {
        if (std.os.windows.kernel32.SetConsoleCtrlHandler(winCtrlHandler, 1) == 0) {
            return error.FailedToSetCtrlHandler;
        }
        return;
    }

    const action = std.posix.Sigaction{
        .handler = .{ .handler = unixSigintHandler },
        .mask = undefined,
        .flags = 0,
    };

    _ = std.posix.sigaction(std.posix.SIG.INT, &action, null);
}

fn winCtrlHandler(ctrl_type: std.os.windows.DWORD) callconv(.c) std.os.windows.BOOL {
    _ = ctrl_type;
    exit_requested = true;
    return 1;
}

fn unixSigintHandler(sig_num: i32) callconv(.c) void {
    _ = sig_num;
    exit_requested = true;
}
