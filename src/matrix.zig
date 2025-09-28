const std = @import("std");

const MiniLCG = @import("mini_lcg.zig").MiniLCG;
const Printer = @import("printer.zig").Printer;

const Column = struct {
    cursor: usize,
    column: []u8,
};

pub const Matrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    printer: *Printer,

    matrix: ?[]Column = null,
    
    debugMode: bool = false,

    pub fn initialize(self: *Matrix, cols: usize, rows: usize) !*Matrix {
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

        return self;
    }

    pub fn print(self: *Matrix) !*Matrix {
        if (self.matrix == null) {
            return self;
        }

        const matrix = self.matrix.?;

        if (matrix.len == 0) {
            return self;
        }

        const rows = matrix.len;
        const cols = matrix[0].column.len;

        if (self.debugMode) {
            for (0..rows) |r| {
                try self.printer.printf("{d}", .{matrix[r].cursor});
            }
        }

        for (0..cols) |c| {
            for (0..rows) |r| {
                try self.printer.printf("{c}", .{matrix[r].column[c]});
            }
            if (c < cols - 1) {
                try self.printer.printf("\n", .{});
            }
        }

        return self;
    }

    pub fn free(self: *Matrix) *Matrix {
        if (self.matrix == null) {
            return self;
        }
        
         const matrix = self.matrix.?;

        for (matrix) |column| {
            self.allocator.free(column.column);
        }

        self.allocator.free(matrix);

        return self;
    }
};
