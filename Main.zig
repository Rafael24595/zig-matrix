const std = @import("std");
const builtin = @import("builtin");

const console = @import("src/console.zig");
const matrix = @import("src/matrix.zig");

const MiniLCG = @import("src/mini_lcg.zig").MiniLCG;
const Printer = @import("src/printer.zig").Printer;

var isDebug = true;

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    var lcg = MiniLCG{ .seed = 12345 };
    var printer = Printer{ .arena = &arena, .out = std.fs.File.stdout() };

    const winsize = try console.winSize();

    // Tested on Windows CMD.
    var space: usize = 1;
    if (isDebug) {
        space += 3;
    }

    const cols = winsize.cols;
    const rows = winsize.rows - space;

    var mtrx = matrix.Matrix{ .allocator = &allocator, .lcg = &lcg, .printer = &printer, .debugMode = isDebug };

    _ = try mtrx.initialize(cols, rows);

    if (isDebug) {
        try printer.printf("Terminal: {d} rows x {d} columns\n", .{ rows, cols });
        try printer.printf("Matrix of {d}x{d}\n", .{ rows, cols });
    }

    _ = try mtrx.print();

    // TODO: Implement matrix steps.
    for (0..10) |frame| {
        try printer.printf("[TEST_LOOP] Frame {d}\n", .{frame});
        std.Thread.sleep(1 * std.time.ns_per_s);
        printer.reset();
    }

    std.Thread.sleep(3 * std.time.ns_per_s);

    try printer.print(console.CLEAN_CONSOLE);

    _ = mtrx.free();
}
