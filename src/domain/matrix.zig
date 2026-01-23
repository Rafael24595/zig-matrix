const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

const AsciiGenerator = @import("symbol.zig").SymbolGenerator;
const ColorScale = @import("color.zig").ColorScale;

pub const Mode = enum {
    Rain,
    Wave,
    Wall,
};

const Meta = struct {
    cursor: usize,
    delay: usize,
    loop: usize,
};

pub const LinearMatrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    ascii: *AsciiGenerator,
    scale: *ColorScale,

    mode: Mode = Mode.Rain,

    cols: usize = 0,
    rows: usize = 0,

    mtrx: ?[][]const u8 = null,
    meta: ?[]Meta = null,

    pub fn init(allocator: *std.mem.Allocator, lcg: *MiniLCG, ascii: *AsciiGenerator, scale: *ColorScale, mode: Mode) @This() {
        return LinearMatrix{
            .allocator = allocator,
            .lcg = lcg,
            .ascii = ascii,
            .scale = scale,
            .mode = mode,
        };
    }

    pub fn build(self: *@This(), cols: usize, rows: usize) !void {
        self.cols = cols;
        self.rows = rows;

        self.mtrx = try self.allocator.alloc([]const u8, cols * rows);
        self.meta = try self.allocator.alloc(Meta, cols);

        const mtrx = self.mtrx.?;
        const meta = self.meta.?;

        const delayMode: u8 = switch (self.mode) {
            Mode.Rain => @intCast(rows),
            Mode.Wave => @intCast(5),
            Mode.Wall => 0,
        };

        for (0..self.cols) |x| {
            const delay = self.lcg.randInRange(0, delayMode);

            meta[x].cursor = 0;
            meta[x].loop = 0;
            meta[x].delay = @intCast(delay);

            const col_start = x * self.rows;

            for (0..self.rows) |y| {
                const cursor = col_start + y;
                mtrx[cursor] = self.ascii.next();
            }
        }
    }

    pub fn max_char_bytes(self: *@This()) usize {
        return self.ascii.max_bytes();
    }

    pub fn vector(self: *@This()) ?[][]const u8 {
        return self.mtrx;
    }

    pub fn metadata(self: *@This()) ?[]Meta {
        return self.meta;
    }

    pub fn cols_len(self: *@This()) usize {
        return self.cols;
    }

    pub fn rows_len(self: *@This()) usize {
        return self.rows;
    }

    pub fn next(self: *@This()) !void {
        if (self.mtrx == null) {
            return;
        }

        std.debug.assert(self.meta != null);

        const meta = self.meta.?;

        for (meta) |*col| {
            if (col.delay > 0) {
                col.delay = col.delay - 1;
                continue;
            }

            if (col.cursor < self.rows - 1) {
                col.cursor += 1;
                continue;
            }

            col.cursor = 0;
            col.loop += 1;
        }
    }

    pub fn free(self: *@This()) void {
        if (self.mtrx != null) {
            self.allocator.free(self.mtrx.?);
        }

        if (self.meta != null) {
            self.allocator.free(self.meta.?);
        }
    }
};
