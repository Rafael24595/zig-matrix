const std = @import("std");
const builtin = @import("builtin");

const color = @import("src/color.zig");
const console = @import("src/console.zig");
const matrix = @import("src/matrix.zig");

const MiniLCG = @import("src/mini_lcg.zig").MiniLCG;
const ascii = @import("src/ascii.zig");
const Printer = @import("src/printer.zig").Printer;

var exit_requested: bool = false;

var isDebug = true;
var seed: u32 = 1234;
var speed: u64 = 50;
var rainColor = color.Colors.Green;
var asciiMode = ascii.Mode.Default;
var matrixMode = matrix.Mode.Rain;
var dropLen: usize = 10;

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    try run(&allocator, &arena);
}

pub fn run(allocator: *std.mem.Allocator, arena: *std.heap.ArenaAllocator) !void {
    try defineSignalHandlers();

    var lcg = MiniLCG{ .seed = seed };
    var printer = Printer{ .arena = arena, .out = std.fs.File.stdout() };

    var asciiGenerator = ascii.AsciiGenerator.new(&lcg, asciiMode);
    var scale = color.ColorScale{ .allocator = allocator };
    try scale.initialize(dropLen, rainColor);

    while (!exit_requested) {
        const winsize = try console.winSize();

        // Tested on Windows CMD.
        var space: usize = 0;
        if (isDebug) {
            space += 3;
        }

        const area = winsize.cols * winsize.rows;

        const cols = winsize.cols;
        const rows = winsize.rows - space;

        var mtrx = matrix.Matrix{ .allocator = allocator, .lcg = &lcg, .printer = &printer, .ascii = &asciiGenerator, .scale = &scale, .mode = matrixMode, .debugMode = isDebug };

        try mtrx.initialize(cols, rows);

        try printer.print(console.CLEAN_CONSOLE);
        try printer.print(console.HIDE_CURSOR);

        while (!exit_requested) {
            try printer.print(console.RESET_CURSOR);
            if (isDebug) {
                try printer.printf("Seed: {d}\n", .{seed});
                try printer.printf("Speed: {d}ms | Ascii Mode: {any} | Rain color: {any} | Matrix Mode: {any}\n", .{ speed, asciiMode, rainColor, matrixMode });
                try printer.printf("Matrix: {d} | Columns: {d} | Rows: {d} | Drop lenght: {d}\n", .{ rows * cols, cols, rows, dropLen });
            }
            try mtrx.print();
            try mtrx.next();
            std.Thread.sleep(speed * std.time.ns_per_ms);
            printer.reset();

            const newWinsize = try console.winSize();
            if (area != newWinsize.cols * newWinsize.rows) {
                break;
            }
        }

        try printer.print(console.CLEAN_CONSOLE);

        mtrx.free();
    }

    scale.free();
    _ = arena.reset(.free_all);

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

    _ = std.os.signal(std.os.SIGINT, unixSigintHandler);
}

fn winCtrlHandler(ctrl_type: std.os.windows.DWORD) callconv(.c) std.os.windows.BOOL {
    _ = ctrl_type;
    exit_requested = true;
    return 1;
}

fn unixSigintHandler(signum: c_int) c_int {
    _ = signum;
    exit_requested = true;
    return 0;
}
