const std = @import("std");

const Printer = @import("printer.zig").Printer;

const ColorScale = @import("../domain/color.zig").ColorScale;
const Matrix = @import("../domain/matrix.zig").Matrix;

pub const Mode = enum {
    Rain,
    Wave,
    Wall,
};

const Column = struct {
    cursor: usize,
    delay: usize,
    loop: usize,
    column: []u8,
};

pub fn MatrixPrinter(
    comptime character_fmt: []const u8,
) type {
    return struct {
        allocator: *std.mem.Allocator,

        printer: *Printer,
        scale: *ColorScale,

        pub fn init(allocator: *std.mem.Allocator, printer: *Printer, scale: *ColorScale) MatrixPrinter(character_fmt) {
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

            const maxCharSize = 25;
            const estimatedSize = rows * cols * maxCharSize;
            var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, estimatedSize);
            defer buffer.deinit(self.allocator.*);

            for (0..cols) |column| {
                for (0..rows) |row| {
                    const rowRef = matrix[row];

                    const iCursor: i32 = @intCast(rowRef.cursor);
                    const iColumn: i32 = @intCast(column);
                    const iColumns: i32 = @intCast(cols);

                    var scaleIndex = iCursor - iColumn;

                    const tailRange = scaleLen - iCursor;
                    const tailStart = iColumns - tailRange;

                    if (rowRef.delay > 0) {
                        try buffer.append(self.allocator.*, ' ');
                        continue;
                    }

                    if (scaleIndex < 0) {
                        if (rowRef.loop == 0) {
                            try buffer.append(self.allocator.*, ' ');
                            continue;
                        }

                        if (column < tailStart) {
                            try buffer.append(self.allocator.*, ' ');
                            continue;
                        }

                        scaleIndex = (scaleLen + tailStart) - iColumn;
                    }

                    const color = self.scale.find(@intCast(scaleIndex));
                    if (color == null) {
                        try buffer.append(self.allocator.*, ' ');
                        continue;
                    }

                    const args = .{ color.?[0], color.?[1], color.?[2], rowRef.column[column] };
                    const formatted = try self.printer.format(character_fmt, args);

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
