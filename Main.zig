const std = @import("std");
const builtin = @import("builtin");

var seed: u32 = 0;
var isDebug = true;

const Column = struct {
    cursor: usize,
    column: []u8,
};

pub fn main() !void {
    seed = 12345;

    const winsize = try winSize();

    // Tested on Windows CMD.
    var space: usize = 1;
    if (isDebug) {
        space += 3;
    }

    const cols = winsize.cols;
    const rows = winsize.rows - space;

    // TODO: Handle with debug flag.
    if (isDebug) {
        std.debug.print("Terminal: {d} rows x {d} columns\n", .{ rows, cols });
        std.debug.print("Matrix of {d}x{d}\n", .{ rows, cols });
    }

    var allocator = std.heap.page_allocator;

    const matrix = try createMatrix(&allocator, cols, rows);

    printMatrix(matrix);

    freeMatrix(&allocator, matrix);
}

fn createMatrix(allocator: *std.mem.Allocator, cols: usize, rows: usize) ![]Column {
    const matrix = try allocator.alloc(Column, cols);

    const ascii_start: u8 = 32;
    const ascii_end: u8 = 126;

    for (matrix) |*column| {
        column.column = try allocator.alloc(u8, rows);
        column.cursor = 0;
        for (column.column) |*cell| {
            const random_char = randInRange(ascii_start, ascii_end);
            cell.* = random_char;
        }
    }

    return matrix;
}

fn printMatrix(matrix: []Column) void {
    if (matrix.len == 0) {
        return;
    }

    const rows = matrix.len;
    const cols = matrix[0].column.len;
    
    if (isDebug) {
        for (0..rows) |r| {
            std.debug.print("{d}", .{matrix[r].cursor});
        }
    }

    for (0..cols) |c| {
        for (0..rows) |r| {
            std.debug.print("{c}", .{matrix[r].column[c]});
        }
        if (c < cols - 1) {
            std.debug.print("\n", .{});
        }
    }
}

fn freeMatrix(allocator: *std.mem.Allocator, matrix: []Column) void {
    for (matrix) |column| {
        allocator.free(column.column);
    }

    allocator.free(matrix);
}

const WinSize = struct {
    cols: usize,
    rows: usize,
};

fn winSize() !WinSize {
    return switch (builtin.os.tag) {
        .linux => linuxWinSize(),
        .windows => windowsWinSize(),
        else => WinSize{ .cols = 0, .rows = 0 },
    };
}

fn linuxWinSize() !WinSize {
    var ws: std.posix.winsize = undefined;

    const err = std.os.linux.ioctl(
        std.posix.STDOUT_FILENO,
        std.os.linux.T.IOCGWINSZ,
        @intFromPtr(&ws),
    );

    if (err == -1) {
        return error.IoctlFailed;
    }

    const cols: usize = @intCast(ws.col);
    const rows: usize = @intCast(ws.row);

    return WinSize{ .cols = cols, .rows = rows };
}

fn windowsWinSize() !WinSize {
    var info: std.os.windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;

    const hConsole = std.os.windows.kernel32.GetStdHandle(std.os.windows.STD_OUTPUT_HANDLE) orelse return error.NoStdout;

    const ok = std.os.windows.kernel32.GetConsoleScreenBufferInfo(hConsole, &info);
    if (ok == 0) return error.WinAPI;

    const rows: usize = @intCast(info.srWindow.Bottom - info.srWindow.Top + 1);
    const cols: usize = @intCast(info.srWindow.Right - info.srWindow.Left + 1);

    return WinSize{ .cols = cols, .rows = rows };
}

fn randInRange(min: u8, max: u8) u8 {
    const mul = @mulWithOverflow(seed, 1664525);
    const add = @addWithOverflow(mul[0], 1013904223);
    seed = add[0];

    const min32: u32 = @intCast(min);
    const max32: u32 = @intCast(max);

    const range: u32 = max32 - min32 + 1;
    const value: u32 = seed % range;

    return @intCast(min32 + value);
}