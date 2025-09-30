const std = @import("std");

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
    printer: *Printer,
    scale: *ColorScale,

    matrix: ?[]Column = null,
    
    mode: Mode = Mode.Rain,
    debugMode: bool = false,

    pub fn initialize(self: *Matrix, cols: usize, rows: usize) !void {
        self.matrix = try self.allocator.alloc(Column, cols);

        const matrix = self.matrix.?;

        const ascii_start: u8 = 32;
        const ascii_end: u8 = 126;

        const delayMode: u8 = switch (self.mode) {
            Mode.Rain => @intCast(rows),
            Mode.Wave => @intCast(5),
            Mode.Wall => 0
        };

        for (matrix) |*column| {
            const delay = self.lcg.randInRange(0, delayMode);
            column.column = try self.allocator.alloc(u8, rows);
            column.cursor = 0;
            column.loop = 0;
            column.delay = @intCast(delay);
            for (column.column) |*cell| {
                const random_char = self.lcg.randInRange(ascii_start, ascii_end);
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

            if(column.cursor == column.column.len - 1) {
                column.cursor = 0;
                column.loop = column.loop + 1;
                continue;
            }

            column.cursor = column.cursor + 1;
        }
    }

    // TODO: Rafactor.
    pub fn print(self: *Matrix) !void {
        if (self.matrix == null or self.matrix.?.len == 0) {
            return;
        }

        const matrix = self.matrix.?;
        const rows = matrix.len;
        const cols = matrix[0].column.len;

        if (self.debugMode) {
            for (0..rows) |r| {
                try self.printer.printf("{d}", .{matrix[r].cursor});
            }
        }

        const scaleLen: i32 = @intCast(self.scale.len() - 2);

        var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, 0);
        defer buffer.deinit(self.allocator.*);

        for (0..cols) |c| {
            for (0..rows) |r| {
                const scaleIndex = self.findScaleIndex(scaleLen, cols, r, c);
                if (scaleIndex == null) {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                }

                const color = self.scale.find(@intCast(scaleIndex.?));
                if (color == null) {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                }

                const formatted = try self.printer.format(console.SCALED_CHARACTER, .{ color.?[0], color.?[1], color.?[2], matrix[r].column[c] });
                try buffer.appendSlice(self.allocator.*, formatted);
            }

            if (c < cols - 1) {
                try buffer.append(self.allocator.*, '\n');
            }
        }

        try self.printer.print(buffer.items);
    }

    pub fn findScaleIndex(self: *Matrix, scaleLen: i32, columns: usize, row: usize, column: usize) ?i32 {
        const iCursor: i32 = @intCast(self.matrix.?[row].cursor);
        const iColumn: i32 = @intCast(column);
        const iColumns: i32 = @intCast(columns);

        const scaleIndex = iCursor - iColumn;
        
        const tailRange = scaleLen - iCursor;
        const tailStart = iColumns - tailRange;

        const isWaiting = self.matrix.?[row].delay > 0;
        const isTailIndexOnFirstLoop = scaleIndex < 0 and self.matrix.?[row].loop == 0;
        const isTailIndexUnderRange = scaleIndex < 0 and column < tailStart;
        if (isWaiting or isTailIndexOnFirstLoop or isTailIndexUnderRange) {
            return null;
        }

        if (scaleIndex < 0 and column >= tailStart) {
            return (scaleLen + tailStart) - iColumn;
        }

        return scaleIndex;
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
