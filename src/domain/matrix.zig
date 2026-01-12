const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

const AsciiGenerator = @import("ascii.zig").AsciiGenerator;
const ColorScale = @import("color.zig").ColorScale;

pub const Mode = enum {
    Rain,
    Wave,
    Wall,
};

const Column = struct {
    cursor: usize,
    delay: usize,
    loop: usize,
    column: [][]const u8,
};

pub const Matrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    ascii: *AsciiGenerator,
    scale: *ColorScale,

    mode: Mode = Mode.Rain,

    matrix: ?[]Column = null,

    pub fn init(allocator: *std.mem.Allocator, lcg: *MiniLCG, ascii: *AsciiGenerator, scale: *ColorScale, mode: Mode) @This() {
        return Matrix{ .allocator = allocator, .lcg = lcg, .ascii = ascii, .scale = scale, .mode = mode };
    }

    pub fn build(self: *@This(), cols: usize, rows: usize) !void {
        self.matrix = try self.allocator.alloc(Column, cols);

        const matrix = self.matrix.?;

        const delayMode: u8 = switch (self.mode) {
            Mode.Rain => @intCast(rows),
            Mode.Wave => @intCast(5),
            Mode.Wall => 0,
        };

        for (matrix) |*column| {
            const delay = self.lcg.randInRange(0, delayMode);
            column.column = try self.allocator.alloc([]const u8, rows);
            column.cursor = 0;
            column.loop = 0;
            column.delay = @intCast(delay);
            for (column.column) |*cell| {
                const random_char = self.ascii.next();
                cell.* = random_char;
            }
        }
    }

    pub fn max_char_bytes(self: *@This()) usize {
        return self.ascii.max_bytes();
    }

    pub fn next(self: *@This()) !void {
        if (self.matrix == null) {
            return;
        }

        const matrix = self.matrix.?;
        if (matrix.len == 0) {
            return;
        }

        for (matrix) |*column| {
            if (column.delay > 0) {
                column.delay = column.delay - 1;
                continue;
            }

            if (column.cursor == column.column.len - 1) {
                column.cursor = 0;
                column.loop = column.loop + 1;
                continue;
            }

            column.cursor = column.cursor + 1;
        }
    }

    pub fn free(self: *@This()) void {
        if (self.matrix == null) {
            return;
        }

        const matrix = self.matrix.?;

        for (matrix) |column| {
            self.allocator.free(column.column);
        }

        self.allocator.free(matrix);

        return;
    }
};
