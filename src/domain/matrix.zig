const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

const AsciiGenerator = @import("symbol.zig").SymbolGenerator;
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

    mtrx: ?[]Column = null,

    pub fn init(allocator: *std.mem.Allocator, lcg: *MiniLCG, ascii: *AsciiGenerator, scale: *ColorScale, mode: Mode) @This() {
        return Matrix{ .allocator = allocator, .lcg = lcg, .ascii = ascii, .scale = scale, .mode = mode };
    }

    pub fn build(self: *@This(), c: usize, r: usize) !void {
        self.mtrx = try self.allocator.alloc(Column, c);

        const mtrx = self.mtrx.?;

        const delayMode: u8 = switch (self.mode) {
            Mode.Rain => @intCast(r),
            Mode.Wave => @intCast(5),
            Mode.Wall => 0,
        };

        for (mtrx) |*column| {
            const delay = self.lcg.randInRange(0, delayMode);
            column.column = try self.allocator.alloc([]const u8, r);
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

    pub fn matrix(self: *@This()) ?[]Column {
        return self.mtrx;
    }

    pub fn cols(self: *@This()) usize {
        if (self.mtrx) |mtrx| {
            return mtrx[0].column.len;
        }
        return 0;
    }

    pub fn rows(self: *@This()) usize {
        if (self.mtrx) |mtrx| {
            return mtrx.len;
        }
        return 0;
    }

    pub fn next(self: *@This()) !void {
        if (self.matrix() == null) {
            return;
        }

        const mtrx = self.matrix().?;
        if (mtrx.len == 0) {
            return;
        }

        for (mtrx) |*column| {
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
        if (self.matrix() == null) {
            return;
        }

        const mtrx = self.matrix().?;

        for (mtrx) |column| {
            self.allocator.free(column.column);
        }

        self.allocator.free(mtrx);

        return;
    }
};
