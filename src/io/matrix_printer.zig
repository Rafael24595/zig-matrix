const std = @import("std");

const Printer = @import("printer.zig").Printer;

const ColorScale = @import("../domain/color.zig").ColorScale;
const Matrix = @import("../domain/matrix.zig").Matrix;
const Formatter = @import("formatter.zig").FormatterUnion;

pub const MatrixPrinter = struct {
    allocator: *std.mem.Allocator,

    printer: *Printer,
    scale: *ColorScale,
    formatter: Formatter,

    pub fn init(allocator: *std.mem.Allocator, printer: *Printer, formatter: Formatter, scale: *ColorScale) MatrixPrinter {
        return .{ .allocator = allocator, .printer = printer, .scale = scale, .formatter = formatter };
    }

    // TODO: Refactor after checking the performance impact.
    pub fn print(self: *@This(), mtrx: *Matrix) !void {
        if (mtrx.matrix == null or mtrx.matrix.?.len == 0) {
            return;
        }

        const matrix = mtrx.matrix.?;
        const rows = matrix.len;
        const columns = matrix[0].column.len;

        const prefix = self.formatter.prefix();
        const sufix = self.formatter.sufix();

        const estimatedSize = prefix.len + (rows * columns * self.formatter.fmt_bytes()) + sufix.len;
        var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, estimatedSize);
        defer buffer.deinit(self.allocator.*);

        const buf = try self.allocator.alloc(u8, self.formatter.fmt_bytes());
        defer self.allocator.free(buf);

        if (prefix.len > 0) {
            try buffer.appendSlice(self.allocator.*, prefix);
        }

        for (0..columns) |column| {
            for (0..rows) |row| {
                const rowRef = matrix[row];
                if (rowRef.delay > 0) {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                }

                const cursor = rowRef.cursor;
                const scaleIndex = (columns + cursor - column) % columns;
                if (rowRef.loop == 0 and cursor < column) {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                }

                const color = self.scale.findUnsafe(scaleIndex) orelse {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                };

                const formatted = try self.formatter.format(buf, color[0], color[1], color[2], rowRef.column[column]);
                try buffer.appendSlice(self.allocator.*, formatted);
            }

            if (column < columns - 1) {
                try buffer.append(self.allocator.*, '\n');
            }
        }

        if (sufix.len > 0) {
            try buffer.appendSlice(self.allocator.*, sufix);
        }

        try self.printer.print(buffer.items);
    }
};
