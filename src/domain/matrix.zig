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

    /// Indicates whether the column is currently paused. A paused column will
    /// not advance its cursor until it is reset by the matrix.
    pause_pending: bool = false,
    /// Number of cycles the column has been paused. A column is considered
    /// fully paused when this value is greater than zero.
    pause_cycles: usize = 0,
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
    /// Maximum delay value used to initialize column delays based on the selected mode.
    delay_mode: usize = 0,

    /// Number of columns in the matrix.
    cols: usize = 0,
    /// Number of rows in the matrix.
    rows: usize = 0,

    /// Matrix symbols stored in column-major order, or null before allocation.
    mtrx: ?[][]const u8 = null,
    /// Animation state for each column, or null before allocation.
    meta: ?[]Meta = null,

    /// Indicates whether a pause has been requested for the matrix. When true,
    /// all columns will enter a paused state on the next update.
    pause_requested: bool = false,

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

        self.delay_mode = switch (self.mode) {
            Mode.rain => rows,
            Mode.wave => 5,
            Mode.wall => 0,
        };

        for (0..self.cols) |x| {
            const delay = self.lcg.rand_in_range(0, self.delay_mode);

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

    /// Requests a pause for the matrix, causing all columns to enter a paused state on the next update.
    /// If the matrix is already paused, this function unlocks the pause and allows the columns to resume advancing.
    pub fn toggle_pause(self: *@This()) void {
        self.pause_requested = !self.pause_requested;
    }

    /// Advances the animation state of each column by one update.
    ///
    /// Columns first count down their delay, then advance their cursor.
    /// Once a cursor reaches the final row, it returns to zero and its
    /// completed-cycle counter is incremented. Does nothing if the matrix
    /// has not been allocated.
    pub fn next(self: *@This()) !void {
        if (comptime std.debug.runtime_safety) {
            std.debug.assert(self.mtrx != null);
            std.debug.assert(self.meta != null);
        }

        const meta = self.meta orelse return;

        if (self.pause_requested) {
            for (meta) |*col| {
                self.advance_to_pause(col);
            }
            return;
        }

        for (meta) |*col| {
            if (col.pause_pending) {
                self.advance_to_pause(col);
            } else {
                self.advance_column(col);
            }
        }

        self.reset();
    }

    inline fn advance_to_pause(self: *@This(), col: *Meta) void {
        if (col.delay > 0) {
            return;
        }

        if (!col.pause_pending) {
            self.advance_column(col);
            if (col.cursor > 0) {
                return;
            }

            col.pause_pending = true;
            col.pause_cycles = 0;
        }

        if (col.pause_cycles == 0) {
            self.advance_column(col);
            if (col.cursor > 0) {
                return;
            }

            col.pause_cycles += 1;
        }

        col.delay = 1;
    }

    inline fn advance_column(self: *@This(), col: *Meta) void {
        if (col.delay > 0) {
            col.delay = col.delay - 1;
            return;
        }

        if (col.cursor < self.rows - 1) {
            col.cursor += 1;
            return;
        }

        col.cursor = 0;
        col.loop += 1;
    }

    inline fn reset(self: *@This()) void {
        for (self.meta.?[0..self.cols]) |*col| {
            if (!col.pause_pending or col.pause_cycles == 0) {
                continue;
            }

            const delay = self.lcg.rand_in_range(0, self.delay_mode);

            col.* = .{
                .cursor = 0,
                .loop = 0,
                .delay = delay,
                .pause_pending = false,
                .pause_cycles = 0,
            };
        }
    }
};

fn make_test_matrix(
    allocator: std.mem.Allocator,
    rows: usize,
) !LinearMatrix {
    var matrix = LinearMatrix.init(
        allocator,
        undefined,
        undefined,
        undefined,
        .rain,
    );

    matrix.cols = 1;
    matrix.rows = rows;

    matrix.mtrx = try allocator.alloc([]const u8, rows);
    @memset(matrix.mtrx.?, "");

    errdefer allocator.free(matrix.mtrx.?);

    matrix.meta = try allocator.alloc(Meta, 1);
    matrix.meta.?[0] = .{
        .cursor = 0,
        .delay = 0,
        .loop = 0,
        .pause_pending = false,
        .pause_cycles = 0,
    };

    return matrix;
}

test "free can be called multiple times" {
    const allocator = std.testing.allocator;

    var matrix = try make_test_matrix(allocator, 4);

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

test "matrix state before build" {
    const allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        allocator,
        undefined,
        undefined,
        undefined,
        .wall,
    );

    try std.testing.expect(matrix.mtrx == null);
    try std.testing.expect(matrix.meta == null);
    try std.testing.expectEqual(0, matrix.cols_len());
    try std.testing.expectEqual(0, matrix.rows_len());
}

test "next decrements delay without advancing the cursor" {
    const allocator = std.testing.allocator;

    var matrix = try make_test_matrix(allocator, 4);
    defer matrix.free();

    matrix.meta.?[0].cursor = 1;
    matrix.meta.?[0].delay = 2;

    try matrix.next();

    try std.testing.expectEqual(1, matrix.meta.?[0].cursor);
    try std.testing.expectEqual(1, matrix.meta.?[0].delay);
}

test "next advances the cursor when delay reaches zero" {
    const allocator = std.testing.allocator;

    var matrix = try make_test_matrix(allocator, 4);
    defer matrix.free();

    matrix.meta.?[0].cursor = 1;
    matrix.meta.?[0].delay = 0;

    try matrix.next();

    try std.testing.expectEqual(2, matrix.meta.?[0].cursor);
}

test "next wraps the cursor and increments the completed cycle count" {
    const allocator = std.testing.allocator;

    var matrix = try make_test_matrix(allocator, 4);
    defer matrix.free();

    matrix.meta.?[0].cursor = 3;
    matrix.meta.?[0].loop = 2;

    try matrix.next();

    try std.testing.expectEqual(0, matrix.meta.?[0].cursor);
    try std.testing.expectEqual(3, matrix.meta.?[0].loop);
}

test "pause preserves the delay while it is positive" {
    const allocator = std.testing.allocator;

    var matrix = try make_test_matrix(allocator, 4);
    defer matrix.free();

    matrix.pause_requested = true;
    matrix.meta.?[0].cursor = 1;
    matrix.meta.?[0].delay = 2;

    try matrix.next();

    try std.testing.expectEqual(1, matrix.meta.?[0].cursor);
    try std.testing.expectEqual(2, matrix.meta.?[0].delay);
    try std.testing.expect(!matrix.meta.?[0].pause_pending);
}

test "pause finishes the current cycle before stopping the column" {
    const allocator = std.testing.allocator;

    var matrix = try make_test_matrix(allocator, 3);
    defer matrix.free();

    matrix.pause_requested = true;
    matrix.meta.?[0].cursor = 1;

    try matrix.next();

    try std.testing.expectEqual(2, matrix.meta.?[0].cursor);

    try matrix.next();

    try std.testing.expectEqual(1, matrix.meta.?[0].cursor);
    try std.testing.expect(matrix.meta.?[0].pause_pending);
}

test "toggle_pause changes the global pause request" {
    const allocator = std.testing.allocator;

    var matrix = LinearMatrix.init(
        allocator,
        undefined,
        undefined,
        undefined,
        .wall,
    );

    try std.testing.expect(!matrix.pause_requested);

    matrix.toggle_pause();
    try std.testing.expect(matrix.pause_requested);

    matrix.toggle_pause();
    try std.testing.expect(!matrix.pause_requested);
}
