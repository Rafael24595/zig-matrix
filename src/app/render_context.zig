const std = @import("std");

const configuration = @import("../configuration/configuration.zig");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

const console = @import("../io/console.zig");
const Printer = @import("../io/printer.zig").Printer;
const LinearMatrixPrinter = @import("../io/matrix_printer.zig").LinearMatrixPrinter;

const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;
const SymbolGenerator = @import("../domain/symbol.zig").SymbolGenerator;
const color = @import("../domain/color.zig");

pub const RenderContext = struct {
    scale: color.ColorScale,
    matrixPrinter: LinearMatrixPrinter,

    last_time: i64,
    last_stable: u16,
    frames: u64,

    pub fn init(
        self: *@This(),
        allocator: *std.mem.Allocator,
        winsize: console.WinSize,
        config: *const configuration.Configuration,
        printer: *Printer,
        lcg: *MiniLCG,
        asciiGenerator: *SymbolGenerator,
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

        self.last_time = 0;
        self.last_stable = 0;
        self.frames = 0;
    }

    pub fn deinit(self: *RenderContext) void {
        self.matrix.free();
        self.scale.free();
    }

    pub fn frame_increment(self: *@This()) void {
        self.frames = self.frames +| 1;
    }

    pub fn frame_per(self: *@This(), interval: i64) u16 {
        const current_time = std.time.milliTimestamp();

        if (self.last_time == 0) {
            self.last_time = current_time;
            return self.last_stable;
        }

        const elapsed = current_time - self.last_time;
        if (elapsed < interval) {
            return self.last_stable;
        }

        if (elapsed > 0) {
            const fps = (self.frames * 1000) / @as(u64, @intCast(elapsed));
            self.last_stable = @intCast(@min(fps, 65535));
        }

        self.last_time = current_time;
        self.frames = 0;

        return self.last_stable;
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
