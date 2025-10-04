const std = @import("std");
const builtin = @import("builtin");

const build = @import("build.zig.zon");

const AllocatorTracer = @import("commons/allocator.zig").AllocatorTracer;
const MiniLCG = @import("commons/mini_lcg.zig").MiniLCG;

const console = @import("io/console.zig");
const Printer = @import("io/printer.zig").Printer;
const MatrixPrinter = @import("io/matrix_printer.zig").MatrixPrinter;

const ascii = @import("domain/ascii.zig");
const color = @import("domain/color.zig");
const matrix = @import("domain/matrix.zig");

var debug = false;

var exit_requested: bool = false;

var seed: u64 = 0;
var milliseconds: u64 = 50;
var dropLen: usize = 10;
var rainColor = color.Color.Green;
var asciiMode = ascii.Mode.Default;
var matrixMode = matrix.Mode.Rain;

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

    try processArgs(persistentAllocator.allocator(), &printer);

    const timestamp = std.time.milliTimestamp();
    seed = @intCast(timestamp);

    try run(&persistentAllocator, &scratchAllocator, &printer);
}

fn processArgs(allocator: std.mem.Allocator, printer: *Printer) !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    defer printer.reset();

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            try printer.printf(
                \\Usage: zig-matrix   [options]
                \\  -h, --help        Show this help message
                \\  -v, --version     Show project's version
                \\  -d                Enable debug mode (default: off)
                \\  -s  <number>      Random seed (default: {d})
                \\  -ms <number>      Frame delay in ms (default: actual date in ms)
                \\  -l <number>       Drop length (default: {d})
                \\  -c  <color>       Rain color (default: {s})
                \\                      (use "help" to list available colors)
                \\  -r  <mode>        ASCII mode (default: {s})
                \\                      (use "help" to list available modes)
                \\  -m  <mode>        Matrix mode (default: {s})
                \\                      (use "help" to list available modes)
                ,
                .{ milliseconds, dropLen,
                   @tagName(rainColor), @tagName(asciiMode), @tagName(matrixMode) }
            );
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            try printer.printf("{any}: {s}\n", .{ build.name, build.version });
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-d")) {
            debug = true;
        } else if (std.mem.eql(u8, arg, "-s")) {
            if (i + 1 >= args.len) {
                try printer.print("Missing argument for -s (seed)\n");
                std.process.exit(1);
            }
            
            const value = args[i + 1];
            seed = std.fmt.parseInt(u64, value, 10) catch {
                try printer.printf("Invalid seed value: {s}\n", .{value});
                std.process.exit(1);
            };
            i += 1;
        } else if (std.mem.eql(u8, arg, "-ms")) {
            if (i + 1 >= args.len) {
                try printer.print("Missing argument for -ms (milliseconds)\n");
                std.process.exit(1);
            }

            const value = args[i + 1];
            milliseconds = std.fmt.parseInt(u64, value, 10) catch {
                try printer.printf("Invalid milliseconds value: {s}\n", .{value});
                std.process.exit(1);
            };
            i += 1;
        } else if (std.mem.eql(u8, arg, "-l")) {
            if (i + 1 >= args.len) {
                try printer.print("Missing argument for -l (drop length)\n");
            }

            const value = args[i + 1];
            dropLen = std.fmt.parseInt(usize, value, 10) catch {
                try printer.printf("Invalid drop length value: {s}\n", .{value});
                std.process.exit(1);
            };
            i += 1;
        } else if (std.mem.eql(u8, arg, "-c")) {
            if (i + 1 >= args.len) {
                try printer.print("Missing argument for -c (color)\n");
                std.process.exit(1);
            }

            const value = args[i + 1];
            if (std.mem.eql(u8, value, "help")) {
                try printEnumOptionsWithTitle(color.Color, "Color", printer);
                std.process.exit(1);
            }

            rainColor = std.meta.stringToEnum(color.Color, value) orelse {
                try printer.printf("Invalid color: {s}\n", .{value});
                try printEnumOptions(color.Color, printer);
                std.process.exit(1);
            };
            i += 1;
        } else if (std.mem.eql(u8, arg, "-r")) {
            if (i + 1 >= args.len) {
                try printer.printf("Missing argument for -r (ASCII mode)\n", .{});
                std.process.exit(1);
            }

            const value = args[i + 1];
            if (std.mem.eql(u8, value, "help")) {
                try printEnumOptionsWithTitle(ascii.Mode, "ASCII mode", printer);
                std.process.exit(1);
            }

            asciiMode = std.meta.stringToEnum(ascii.Mode, value) orelse {
                try printer.printf("Invalid ASCII mode: {s}\n", .{value});
                try printEnumOptions(ascii.Mode, printer);
                std.process.exit(1);
            };
            i += 1;
        } else if (std.mem.eql(u8, arg, "-m")) {
            if (i + 1 >= args.len) {
                try printer.printf("Missing argument for -m (matrix mode)\n", .{});
                std.process.exit(1);
            }

            const value = args[i + 1];
            if (std.mem.eql(u8, value, "help")) {
                try printEnumOptionsWithTitle(matrix.Mode, "Matrix", printer);
                std.process.exit(1);
            }

            matrixMode = std.meta.stringToEnum(matrix.Mode, value) orelse {
                try printer.printf("Invalid matrix mode: {s}\n", .{value});
                try printEnumOptions(matrix.Mode, printer);
                std.process.exit(1);
            };
            i += 1;
        } else {
            try printer.printf("Unknown argument: {s}\n", .{arg});
            std.process.exit(1);
        }
    }
}

fn printEnumOptions(comptime T: type, printer: *Printer) !void {
    try printEnumOptionsWithTitle(T, "Available", printer);
}

fn printEnumOptionsWithTitle(comptime T: type, title: [:0] const u8, printer: *Printer) !void {
    const info = @typeInfo(T);
    try printer.printf("{s} options:\n", .{ title });
    inline for (info.@"enum".fields) |field| {
        try printer.printf(" - {s}\n", .{ field.name });
    }
    try printer.print("\n");
}

pub fn run(persistentAllocator: *AllocatorTracer, scratchAllocator: *AllocatorTracer, printer: *Printer) !void {
    try defineSignalHandlers();

    var allocator = persistentAllocator.allocator();

    var lcg = MiniLCG{ .seed = seed };

    var asciiGenerator = ascii.AsciiGenerator.init(&lcg, asciiMode);
    var scale = try color.ColorScale.init(&allocator, dropLen, color.rgbOf(rainColor));
    var matrixPrinter = MatrixPrinter(console.SCALED_CHARACTER).init(&allocator, printer, &scale);

    while (!exit_requested) {
        const winsize = try console.winSize();

        // Tested on Windows CMD.
        var space: usize = 0;
        if (debug) {
            space += 4;
        }

        const area = winsize.cols * winsize.rows;

        const cols = winsize.cols;
        const rows = winsize.rows - space;

        var mtrx = matrix.Matrix.init(&allocator, &lcg, &asciiGenerator, &scale, matrixMode);
        try mtrx.build(cols, rows);

        try printer.print(console.CLEAN_CONSOLE);
        try printer.print(console.HIDE_CURSOR);

        var persistentBytes = persistentAllocator.bytes();
        var scratchBytes =  scratchAllocator.bytes();
        while (!exit_requested) {
            try printer.print(console.RESET_CURSOR);
            if (debug) {
                try printer.printf("{}: {s}\n", .{ build.name, build.version});
                try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes\n", .{ persistentBytes, scratchBytes});
                try printer.printf("Speed: {d}ms | Ascii Mode: {any} | Rain color: {any} | Matrix Mode: {any}\n", .{ milliseconds, asciiMode, rainColor, matrixMode });
                try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Drop lenght: {d}\n", .{ seed, rows * cols, cols, rows, dropLen });
            }
            try matrixPrinter.print(&mtrx);
            try mtrx.next();
            std.Thread.sleep(milliseconds * std.time.ns_per_ms);

            persistentBytes = persistentAllocator.bytes();
            scratchBytes =  scratchAllocator.bytes();

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
