const std = @import("std");

const configuration = @import("../configuration/configuration.zig");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

const console = @import("../io/console.zig");
const Printer = @import("../io/printer.zig").Printer;
const LinearMatrixPrinter = @import("../io/matrix_printer.zig").LinearMatrixPrinter;
const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;

const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

pub const RenderContext = struct {
    scale: color.ColorScale,
    matrixPrinter: LinearMatrixPrinter,
    matrix: LinearMatrix,

    pub fn init(
        self: *@This(),
        allocator: *std.mem.Allocator,
        winsize: console.WinSize,
        config: *const configuration.Configuration,
        printer: *Printer,
        lcg: *MiniLCG,
        asciiGenerator: *symbol.SymbolGenerator,
    ) !void {
        const space = calculatePadding(config);
        const isVertical = config.orientation == .vertical;

        const cols = if (isVertical)
            winsize.cols
        else
            winsize.rows - space;

        const rows = if (isVertical)
            winsize.rows - space
        else
            winsize.cols;

        const drop: usize = calculateDropLenght(config, rows);

        self.scale = try color.ColorScale.init(
            allocator,
            drop,
            color.rgbOf(config.rainColor),
            config.rain_mode,
        );

        errdefer self.scale.free();

        self.matrixPrinter = LinearMatrixPrinter.init(
            allocator,
            printer,
            config.formatter,
            &self.scale,
            isVertical,
        );

        self.matrix = LinearMatrix.init(
            allocator,
            lcg,
            asciiGenerator,
            &self.scale,
            config.matrix_mode,
        );

        errdefer self.matrix.free();

        try self.matrix.build(cols, rows);
    }

    pub fn deinit(self: *RenderContext) void {
        self.matrix.free();
        self.scale.free();
    }
};

inline fn calculatePadding(config: *const configuration.Configuration) usize {
    var space: usize = 0;
    if (config.debug) {
        space += 4;
    }

    if (config.controls) {
        space += 1;
    }

    return space;
}

inline fn calculateDropLenght(config: *const configuration.Configuration, rows: usize) usize {
    if (config.drop_len > 0) {
        return config.drop_len;
    }

    const f_rows: f32 = @floatFromInt(rows);
    return @intFromFloat(f_rows * config.drop_per);
}
