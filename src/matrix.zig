const std = @import("std");

const console = @import("console.zig");

const MiniLCG = @import("mini_lcg.zig").MiniLCG;
const Printer = @import("printer.zig").Printer;
const ColorScale = @import("color.zig").ColorScale;

const Column = struct {
    cursor: usize,
    column: []u8,
};

pub const Matrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    printer: *Printer,
    scale: *ColorScale,

    matrix: ?[]Column = null,
    
    debugMode: bool = false,

    pub fn initialize(self: *Matrix, cols: usize, rows: usize) !void {
        self.matrix = try self.allocator.alloc(Column, cols);

        const matrix = self.matrix.?;

        const ascii_start: u8 = 32;
        const ascii_end: u8 = 126;

        for (matrix) |*column| {
            column.column = try self.allocator.alloc(u8, rows);
            column.cursor = 0;
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
            if(column.cursor == column.column.len - 1) {
                column.cursor = 0;
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

        var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, 0);
        defer buffer.deinit(self.allocator.*);

        for (0..cols) |c| {
            for (0..rows) |r| {
                const ic: i32 = @intCast(matrix[r].cursor);
                const ir: i32 = @intCast(c);
                const scaleIndex = ic - ir;
                
                if (scaleIndex < 0) {
                    try buffer.append(self.allocator.*, ' ');
                    continue;
                }
                
                const color = self.scale.find(@intCast(scaleIndex));
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
