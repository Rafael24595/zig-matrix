const std = @import("std");

const AsciiGenerator = @import("ascii.zig").AsciiGenerator;
const console = @import("console.zig");

const MiniLCG = @import("mini_lcg.zig").MiniLCG;
const Printer = @import("printer.zig").Printer;
const ColorScale = @import("color.zig").ColorScale;

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

pub const Matrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    ascii: *AsciiGenerator,
    printer: *Printer,
    scale: *ColorScale,

    matrix: ?[]Column = null,

    mode: Mode = Mode.Rain,

    pub fn initialize(self: *Matrix, cols: usize, rows: usize) !void {
        self.matrix = try self.allocator.alloc(Column, cols);

        const matrix = self.matrix.?;

        const delayMode: u8 = switch (self.mode) {
            Mode.Rain => @intCast(rows),
            Mode.Wave => @intCast(5),
            Mode.Wall => 0,
        };

        for (matrix) |*column| {
            const delay = self.lcg.randInRange(0, delayMode);
            column.column = try self.allocator.alloc(u8, rows);
            column.cursor = 0;
            column.loop = 0;
            column.delay = @intCast(delay);
            for (column.column) |*cell| {
                const random_char = self.ascii.next();
                cell.* = random_char;
            }
        }
    }

    pub fn next(self: *Matrix) !void {
        if (self.matrix == null) {
            return;
        }

        const matrix = self.matrix.?;
        if (matrix.len == 0) {
            return;
        }

        for (matrix) |*column| {
            if (column.delay > 0) {
                column.delay = column.delay - 1;
                continue;
            }

            if (column.cursor == column.column.len - 1) {
                column.cursor = 0;
                column.loop = column.loop + 1;
                continue;
            }

            column.cursor = column.cursor + 1;
        }
    }
    
    // TODO: Refactor after checking the performance impact.
    pub fn print(self: *Matrix) !void {
        if (self.matrix == null or self.matrix.?.len == 0) {
            return;
        }

        const matrix = self.matrix.?;
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
                const formatted = try self.printer.format(console.SCALED_CHARACTER, args);
                
                try buffer.appendSlice(self.allocator.*, formatted);
            }

            if (column < cols - 1) {
                try buffer.append(self.allocator.*, '\n');
            }
        }

        try self.printer.print(buffer.items);
    }

    pub fn free(self: *Matrix) void {
        if (self.matrix == null) {
            return;
        }

        const matrix = self.matrix.?;

        for (matrix) |column| {
            self.allocator.free(column.column);
        }

        self.allocator.free(matrix);

        return;
    }
};
