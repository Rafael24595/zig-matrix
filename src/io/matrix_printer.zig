const std = @import("std");

const Printer = @import("terminal_kit").printer.Printer;

const ColorScale = @import("../domain/color.zig").ColorScale;
const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;
const Meta = @import("../domain/matrix.zig").Meta;
const Formatter = @import("formatter.zig").FormatterUnion;

/// Renders a linear matrix as formatted terminal output.
pub const LinearMatrixPrinter = struct {
    /// Allocator used to allocate the internal buffers.
    allocator: *std.mem.Allocator,

    /// Destination printer used to emit the completed frame.
    printer: *Printer,
    /// Color scale used to map matrix positions to RGB values.
    scale: *ColorScale,
    /// Formatter used to encode each visible character.
    formatter: Formatter,
    /// Whether rows are rendered vertically rather than horizontally.
    vertical: bool,

    /// Accumulates the complete formatted frame before output.
    buffer: std.ArrayList(u8),
    /// Scratch buffer used to format individual characters.
    format: []u8,

    /// Initializes a matrix printer and allocates its working buffers.
    ///
    /// Borrows `printer`, `scale`, and the formatter's related resources.
    /// The caller must call `free()` when the printer is no longer needed.
    pub fn init(
        allocator: *std.mem.Allocator,
        printer: *Printer,
        formatter: Formatter,
        scale: *ColorScale,
        matrix: *LinearMatrix,
        vertical: bool,
    ) !@This() {
        const rows = matrix.rows_len();
        const cols = matrix.cols_len();

        const prefix = formatter.prefix();
        const sufix = formatter.sufix();

        const char_fmt_len = formatter.fmt_bytes() + matrix.max_char_bytes();
        const mtrx_fmt_len = rows * cols * char_fmt_len;
        const estimatedSize = prefix.len + mtrx_fmt_len + sufix.len;

        const buffer = try std.ArrayList(u8).initCapacity(allocator.*, estimatedSize);
        const format_buf = try allocator.alloc(u8, formatter.fmt_bytes());

        return .{
            .allocator = allocator,
            .printer = printer,
            .scale = scale,
            .formatter = formatter,
            .vertical = vertical,
            .buffer = buffer,
            .format = format_buf,
        };
    }

    /// Releases the buffers owned by this printer.
    pub fn free(self: *@This()) void {
        self.buffer.deinit(self.allocator.*);
        self.allocator.free(self.format);
    }

    /// Formats and emits the current matrix frame.
    ///
    /// An uninitialized or empty matrix produces no output.
    /// Errors from buffer growth or the underlying printer are propagated.
    pub fn print(self: *@This(), mtrx: *LinearMatrix) !void {
        if (mtrx.vector() == null or mtrx.vector().?.len == 0) {
            return;
        }

        self.buffer.clearRetainingCapacity();

        const prefix = self.formatter.prefix();
        const sufix = self.formatter.sufix();

        if (prefix.len > 0) {
            try self.buffer.appendSlice(self.allocator.*, prefix);
        }

        if (self.vertical) {
            try self.print_vertical(mtrx);
        } else {
            try self.print_horizontal(mtrx);
        }

        if (sufix.len > 0) {
            try self.buffer.appendSlice(self.allocator.*, sufix);
        }

        try self.printer.print(self.buffer.items);
    }

    inline fn print_vertical(
        self: *@This(),
        mtrx: *LinearMatrix,
    ) !void {
        const matrix = mtrx.vector().?;
        const metadata = mtrx.metadata().?;

        const rows = mtrx.rows_len();
        const cols = mtrx.cols_len();

        for (0..rows) |x| {
            const col_start = x * cols;

            for (0..cols) |y| {
                const meta = metadata[y];

                try self.print_cell(
                    matrix,
                    meta,
                    rows,
                    col_start,
                    x,
                    y,
                );
            }

            if (x < rows - 1) {
                try self.buffer.append(self.allocator.*, '\n');
            }
        }
    }

    inline fn print_horizontal(
        self: *@This(),
        mtrx: *LinearMatrix,
    ) !void {
        const matrix = mtrx.vector().?;
        const metadata = mtrx.metadata().?;

        const rows = mtrx.rows_len();
        const cols = mtrx.cols_len();

        for (0..cols) |y| {
            const meta = metadata[y];

            for (0..rows) |x| {
                const col_start = x * cols;

                try self.print_cell(
                    matrix,
                    meta,
                    rows,
                    col_start,
                    x,
                    y,
                );
            }

            if (y < cols - 1) {
                try self.buffer.append(self.allocator.*, '\n');
            }
        }
    }

    inline fn print_cell(
        self: *@This(),
        matrix: [][]const u8,
        meta: Meta,
        rows: usize,
        col_start: usize,
        x: usize,
        y: usize,
    ) !void {
        if (meta.delay > 0) {
            try self.buffer.append(self.allocator.*, ' ');
            return;
        }

        const cursor = meta.cursor;
        if (meta.loop == 0 and cursor < x) {
            try self.buffer.append(self.allocator.*, ' ');
            return;
        }

        const scaleIndex = (rows + cursor - x) % rows;

        const color = self.scale.find_unsafe(scaleIndex) orelse {
            try self.buffer.append(self.allocator.*, ' ');
            return;
        };

        const formatted = try self.formatter.format(
            self.format,
            color[0],
            color[1],
            color[2],
            matrix[col_start + y],
        );

        try self.buffer.appendSlice(self.allocator.*, formatted);
    }
};
