const std = @import("std");

const Printer = @import("printer.zig").Printer;

const ColorScale = @import("../domain/color.zig").ColorScale;
const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;
const Meta = @import("../domain/matrix.zig").Meta;
const Formatter = @import("formatter.zig").FormatterUnion;

pub const LinearMatrixPrinter = struct {
    allocator: *std.mem.Allocator,

    printer: *Printer,
    scale: *ColorScale,
    formatter: Formatter,
    vertical: bool,

    pub fn init(
        allocator: *std.mem.Allocator,
        printer: *Printer,
        formatter: Formatter,
        scale: *ColorScale,
        vertical: bool,
    ) @This() {
        return .{
            .allocator = allocator,
            .printer = printer,
            .scale = scale,
            .formatter = formatter,
            .vertical = vertical,
        };
    }

    // TODO: Refactor after checking the performance impact.
    pub fn print(self: *@This(), mtrx: *LinearMatrix) !void {
        if (mtrx.vector() == null or mtrx.vector().?.len == 0) {
            return;
        }

        const rows = mtrx.rows_len();
        const cols = mtrx.cols_len();

        const prefix = self.formatter.prefix();
        const sufix = self.formatter.sufix();

        const char_fmt_len = self.formatter.fmt_bytes() + mtrx.max_char_bytes();
        const mtrx_fmt_len = rows * cols * char_fmt_len;
        const estimatedSize = prefix.len + mtrx_fmt_len + sufix.len;

        var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, estimatedSize);
        defer buffer.deinit(self.allocator.*);

        if (prefix.len > 0) {
            try buffer.appendSlice(self.allocator.*, prefix);
        }

        if (self.vertical) {
            try self.printVertical(mtrx, &buffer);
        } else {
            try self.printHorizontal(mtrx, &buffer);
        }

        if (sufix.len > 0) {
            try buffer.appendSlice(self.allocator.*, sufix);
        }

        try self.printer.print(buffer.items);
    }

    pub fn printVertical(
        self: *@This(),
        mtrx: *LinearMatrix,
        buffer: *std.ArrayList(u8),
    ) !void {
        const matrix = mtrx.vector().?;
        const metadata = mtrx.metadata().?;

        const rows = mtrx.rows_len();
        const cols = mtrx.cols_len();

        const format = try self.allocator.alloc(u8, self.formatter.fmt_bytes());
        defer self.allocator.free(format);

        for (0..rows) |x| {
            const col_start = x * cols;

            for (0..cols) |y| {
                const meta = metadata[y];

                try self.printCell(
                    matrix,
                    meta,
                    rows,
                    col_start,
                    buffer,
                    format,
                    x,
                    y,
                );
            }

            if (x < rows - 1) {
                try buffer.append(self.allocator.*, '\n');
            }
        }
    }

    pub fn printHorizontal(
        self: *@This(),
        mtrx: *LinearMatrix,
        buffer: *std.ArrayList(u8),
    ) !void {
        const matrix = mtrx.vector().?;
        const metadata = mtrx.metadata().?;

        const rows = mtrx.rows_len();
        const cols = mtrx.cols_len();

        const format = try self.allocator.alloc(u8, self.formatter.fmt_bytes());
        defer self.allocator.free(format);

        for (0..cols) |y| {
            const meta = metadata[y];

            for (0..rows) |x| {
                const col_start = x * cols;

                try self.printCell(
                    matrix,
                    meta,
                    rows,
                    col_start,
                    buffer,
                    format,
                    x,
                    y,
                );
            }

            if (y < cols - 1) {
                try buffer.append(self.allocator.*, '\n');
            }
        }
    }

    inline fn printCell(
        self: *@This(),
        matrix: [][]const u8,
        meta: Meta,
        rows: usize,
        col_start: usize,
        buffer: *std.ArrayList(u8),
        format: []u8,
        x: usize,
        y: usize,
    ) !void {
        if (meta.delay > 0) {
            try buffer.append(self.allocator.*, ' ');
            return;
        }

        const cursor = meta.cursor;
        if (meta.loop == 0 and cursor < x) {
            try buffer.append(self.allocator.*, ' ');
            return;
        }

        const scaleIndex = (rows + cursor - x) % rows;

        const color = self.scale.findUnsafe(scaleIndex) orelse {
            try buffer.append(self.allocator.*, ' ');
            return;
        };

        const formatted = try self.formatter.format(
            format,
            color[0],
            color[1],
            color[2],
            matrix[col_start + y],
        );

        try buffer.appendSlice(self.allocator.*, formatted);
    }
};
