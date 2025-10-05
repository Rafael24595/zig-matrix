const std = @import("std");

const Printer = @import("printer.zig").Printer;

const ColorScale = @import("../domain/color.zig").ColorScale;
const Matrix = @import("../domain/matrix.zig").Matrix;

pub fn MatrixPrinter(
    comptime char_fmt_bytes: usize,
    comptime char_fmt: []const u8,
) type {
    return struct {
        allocator: *std.mem.Allocator,

        printer: *Printer,
        scale: *ColorScale,

        pub fn init(allocator: *std.mem.Allocator, printer: *Printer, scale: *ColorScale) MatrixPrinter(char_fmt_bytes, char_fmt) {
            return .{ .allocator = allocator, .printer = printer, .scale = scale };
        }

        // TODO: Refactor after checking the performance impact.
        pub fn print(self: *@This(), mtrx: *Matrix) !void {
            if (mtrx.matrix == null or mtrx.matrix.?.len == 0) {
                return;
            }

            const matrix = mtrx.matrix.?;
            const rows = matrix.len;
            const cols = matrix[0].column.len;

            const scaleLen: i32 = @intCast(self.scale.len() - 2);

            const estimatedSize = rows * cols * char_fmt_bytes;
            var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, estimatedSize);
            defer buffer.deinit(self.allocator.*);

            const iColumns: i32 = @intCast(cols);
            for (0..cols) |column| {
                const iColumn: i32 = @intCast(column);
                for (0..rows) |row| {
                    const rowRef = matrix[row];
                    if (rowRef.delay > 0) {
                        try buffer.append(self.allocator.*, ' ');
                        continue;
                    }

                    const iCursor: i32 = @intCast(rowRef.cursor);

                    var scaleIndex = iCursor - iColumn;
                    if (scaleIndex < 0) {
                        const tailRange = scaleLen - iCursor;
                        const tailStart = iColumns - tailRange;

                        if (rowRef.loop == 0 or iColumn < tailStart) {
                            try buffer.append(self.allocator.*, ' ');
                            continue;
                        }

                        scaleIndex = (scaleLen + tailStart) - iColumn;
                    }

                    const color = self.scale.find(@intCast(scaleIndex)) orelse {
                        try buffer.append(self.allocator.*, ' ');
                        continue;
                    };

                    var temp: [char_fmt_bytes]u8 = undefined;
                    const formatted = try std.fmt.bufPrint(&temp, char_fmt, .{ color[0], color[1], color[2], rowRef.column[column] });
                    
                    try buffer.appendSlice(self.allocator.*, formatted);
                }

                if (column < cols - 1) {
                    try buffer.append(self.allocator.*, '\n');
                }
            }

            try self.printer.print(buffer.items);
        }
    };
}
