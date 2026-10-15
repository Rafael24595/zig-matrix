const std = @import("std");

const terminal_kit = @import("terminal_kit");

const MiniLCG = terminal_kit.mini_lcg.MiniLCG;

const AsciiGenerator = @import("symbol.zig").SymbolGenerator;
const ColorScale = @import("color.zig").ColorScale;

pub const Mode = enum {
    rain,
    wave,
    wall,
};

pub const Meta = struct {
    cursor: usize,
    delay: usize,
    loop: usize,
};

pub const LinearMatrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    ascii: *AsciiGenerator,
    scale: *ColorScale,

    mode: Mode = Mode.rain,

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
        const mtrx = try self.allocator.alloc([]const u8, cols * rows);
        errdefer self.allocator.free(self.mtrx.?);

        const meta = try self.allocator.alloc(Meta, cols);
        errdefer self.allocator.free(self.meta.?);

        self.cols = cols;
        self.rows = rows;

        self.mtrx = mtrx;
        self.meta = meta;

        const delayMode: u8 = switch (self.mode) {
            Mode.rain => @intCast(rows),
            Mode.wave => @intCast(5),
            Mode.wall => 0,
        };

        for (0..self.cols) |x| {
            const delay = self.lcg.rand_in_range(0, delayMode);

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
        if (self.mtrx) |mtrx| {
            self.allocator.free(mtrx);
            self.mtrx = null;
        }

        if (self.meta) |meta| {
            self.allocator.free(meta);
            self.meta = null;
        }
    }
};

test "next does nothing when the matrix is uninitialized" {
    var allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        &allocator,
        undefined,
        undefined,
        undefined,
        .rain,
    );

    defer matrix.free();

    try matrix.next();

    try std.testing.expect(matrix.vector() == null);
    try std.testing.expect(matrix.metadata() == null);
}

test "free can be called multiple times" {
    var allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        &allocator,
        undefined,
        undefined,
        undefined,
        .rain,
    );

    matrix.mtrx = try allocator.alloc([]const u8, 2);
    matrix.meta = try allocator.alloc(Meta, 1);

    matrix.free();
    matrix.free();

    try std.testing.expect(matrix.mtrx == null);
    try std.testing.expect(matrix.meta == null);
}

test "free is safe before build" {
    var allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        &allocator,
        undefined,
        undefined,
        undefined,
        .rain,
    );

    matrix.free();

    try std.testing.expect(matrix.mtrx == null);
    try std.testing.expect(matrix.meta == null);
}

test "next does nothing before build" {
    var allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        &allocator,
        undefined,
        undefined,
        undefined,
        .rain,
    );

    try matrix.next();

    try std.testing.expect(matrix.mtrx == null);
    try std.testing.expect(matrix.meta == null);
    try std.testing.expectEqual(@as(usize, 0), matrix.cols_len());
    try std.testing.expectEqual(@as(usize, 0), matrix.rows_len());
}
