const std = @import("std");

const MiniLCG = @import("terminal_kit").mini_lcg.MiniLCG;

const AsciiGenerator = @import("symbol.zig").SymbolGenerator;
const ColorScale = @import("color.zig").ColorScale;

/// Selects the behavior used to update matrix column cursors.
pub const Mode = enum {
    rain,
    wave,
    wall,
};

/// Stores the animation state for a single matrix column.
///
/// `cursor` identifies the current position, `delay` counts down before
/// advancing, and `loop` tracks completed cycles.
pub const Meta = struct {
    /// Current position of the column cursor, ranging from 0 to `rows - 1`.
    cursor: usize,
    /// Number of updates to wait before advancing the cursor.
    delay: usize,
    /// Number of times the cursor has completed a full cycle through the rows.
    loop: usize,
};

/// Stores a linear matrix of symbols and the animation metadata for its columns.
///
/// The matrix uses column-major indexing: the element at column `x` and row
/// `y` is stored at `x * rows + y`. The symbol generator, color scale, and
/// random number generator are borrowed dependencies and are not owned
/// by this structure.
pub const LinearMatrix = struct {
    /// Allocator used to allocate the matrix and metadata.
    allocator: std.mem.Allocator,

    /// Random number generator used to initialize column delays.
    lcg: *MiniLCG,
    /// Symbol generator used to populate the matrix with symbols.
    ascii: *AsciiGenerator,
    /// Color scale used to render the matrix symbols.
    scale: *ColorScale,

    /// Animation mode used to initialize column delays.
    mode: Mode = Mode.rain,

    /// Number of columns in the matrix.
    cols: usize = 0,
    /// Number of rows in the matrix.
    rows: usize = 0,

    /// Matrix symbols stored in column-major order, or null before allocation.
    mtrx: ?[][]const u8 = null,
    /// Animation state for each column, or null before allocation.
    meta: ?[]Meta = null,

    /// Creates a matrix using the provided allocator and borrowed dependencies.
    /// Does not allocate matrix storage until `build` is called.
    pub fn init(
        allocator: std.mem.Allocator,
        lcg: *MiniLCG,
        ascii: *AsciiGenerator,
        scale: *ColorScale,
        mode: Mode,
    ) @This() {
        return LinearMatrix{
            .allocator = allocator,
            .lcg = lcg,
            .ascii = ascii,
            .scale = scale,
            .mode = mode,
        };
    }

    /// Allocates the matrix and initializes its symbols and column metadata.
    ///
    /// `cols` and `rows` specify the matrix dimensions. Column delays are
    /// initialized according to the selected animation mode.
    pub fn build(self: *@This(), cols: usize, rows: usize) !void {
        const mtrx = try self.allocator.alloc([]const u8, cols * rows);
        errdefer self.allocator.free(self.mtrx.?);

        const meta = try self.allocator.alloc(Meta, cols);
        errdefer self.allocator.free(self.meta.?);

        self.cols = cols;
        self.rows = rows;

        self.mtrx = mtrx;
        self.meta = meta;

        const delayMode: usize = switch (self.mode) {
            Mode.rain => rows,
            Mode.wave => 5,
            Mode.wall => 0,
        };

        for (0..self.cols) |x| {
            const delay = self.lcg.rand_in_range(0, delayMode);

            meta[x].cursor = 0;
            meta[x].loop = 0;
            meta[x].delay = delay;

            const col_start = x * self.rows;

            for (0..self.rows) |y| {
                const cursor = col_start + y;
                mtrx[cursor] = self.ascii.next();
            }
        }
    }

    /// Returns the maximum number of bytes required by a generated symbol.
    pub fn max_char_bytes(self: @This()) usize {
        return self.ascii.max_bytes();
    }

    /// Returns the matrix storage, or null if it has not been allocated.
    pub fn vector(self: @This()) ?[][]const u8 {
        return self.mtrx;
    }

    /// Returns the animation metadata for each column, or null before allocation.
    pub fn metadata(self: @This()) ?[]Meta {
        return self.meta;
    }

    /// Returns the number of columns.
    pub fn cols_len(self: @This()) usize {
        return self.cols;
    }

    /// Returns the number of rows.
    pub fn rows_len(self: @This()) usize {
        return self.rows;
    }

    /// Advances the animation state of each column by one update.
    ///
    /// Columns first count down their delay, then advance their cursor.
    /// Once a cursor reaches the final row, it returns to zero and its
    /// completed-cycle counter is incremented. Does nothing if the matrix
    /// has not been allocated.
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

    /// Releases the allocated matrix storage and column metadata.
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
    const allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        allocator,
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
    const allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        allocator,
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
    const allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        allocator,
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
    const allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        allocator,
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
