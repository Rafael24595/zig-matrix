const std = @import("std");

const Printer = @import("printer.zig").Printer;

const ColorScale = @import("../domain/color.zig").ColorScale;
const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;
const Formatter = @import("formatter.zig").FormatterUnion;

pub const LinearMatrixPrinter = struct {
    allocator: *std.mem.Allocator,

    printer: *Printer,
    scale: *ColorScale,
    formatter: Formatter,

    pub fn init(allocator: *std.mem.Allocator, printer: *Printer, formatter: Formatter, scale: *ColorScale) @This() {
        return .{ .allocator = allocator, .printer = printer, .scale = scale, .formatter = formatter };
    }

    // TODO: Refactor after checking the performance impact.
    pub fn print(self: *@This(), mtrx: *LinearMatrix) !void {
        if (mtrx.vector() == null or mtrx.vector().?.len == 0) {
            return;
        }

        const matrix = mtrx.vector().?;
        const metadata = mtrx.metadata().?;

        const rows = mtrx.rows_len();
        const cols = mtrx.cols_len();

        const prefix = self.formatter.prefix();
        const sufix = self.formatter.sufix();

        const char_fmt_len = self.formatter.fmt_bytes() + mtrx.max_char_bytes();
        const mtrx_fmt_len = rows * cols * char_fmt_len;
        const estimatedSize = prefix.len + mtrx_fmt_len + sufix.len;

        var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, estimatedSize);
        defer buffer.deinit(self.allocator.*);

        const buf = try self.allocator.alloc(u8, self.formatter.fmt_bytes());
        defer self.allocator.free(buf);

        if (prefix.len > 0) {
            try buffer.appendSlice(self.allocator.*, prefix);
        }

        for (0..rows) |x| {
            const col_start = x * cols;

            for (0..cols) |y| {
                const meta = metadata[y];
                if (meta.delay > 0) {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                }

                const cursor = meta.cursor;
                if (meta.loop == 0 and cursor < x) {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                }

                const scaleIndex = (rows + cursor - x) % rows;
                const color = self.scale.findUnsafe(scaleIndex) orelse {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                };

                const formatted = try self.formatter.format(
                    buf,
                    color[0],
                    color[1],
                    color[2],
                    matrix[col_start + y],
                );

                try buffer.appendSlice(self.allocator.*, formatted);
            }

            if (x < rows - 1) {
                try buffer.append(self.allocator.*, '\n');
            }
        }

        if (sufix.len > 0) {
            try buffer.appendSlice(self.allocator.*, sufix);
        }

        try self.printer.print(buffer.items);
    }
};
