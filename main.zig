const std = @import("std");
const builtin = @import("builtin");

const color = @import("src/color.zig");
const console = @import("src/console.zig");
const matrix = @import("src/matrix.zig");

const MiniLCG = @import("src/mini_lcg.zig").MiniLCG;
const Printer = @import("src/printer.zig").Printer;

var isDebug = false;
var speed: u64 = 50;
var scaleLen: usize = 10;

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

    var scale = color.ColorScale{ .allocator = &allocator };
    try scale.initialize(scaleLen, color.Colors.Green);

    var mtrx = matrix.Matrix{ 
        .allocator = &allocator, 
        .lcg = &lcg, 
        .printer = &printer, 
        .scale = &scale,
        .debugMode = isDebug 
    };

    try mtrx.initialize(cols, rows);

    if (isDebug) {
        try printer.printf("Terminal: {d} rows x {d} columns\n", .{ rows, cols });
        try printer.printf("Matrix of {d}x{d}\n", .{ rows, cols });
    }

    try printer.print(console.HIDE_CURSOR);

    // TODO: Implement safe exit handler.
    while (true) {
        try printer.print(console.RESET_CURSOR);
        try mtrx.print();
        try mtrx.next();
        std.Thread.sleep(speed * std.time.ns_per_ms);
        printer.reset();
    }

    try printer.print(console.SHOW_CURSOR);

    mtrx.free();
    scale.free();
}
