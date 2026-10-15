const std = @import("std");

const configuration = @import("../configuration/configuration.zig");

const terminal_kit = @import("terminal_kit");

const Counter = terminal_kit.frame.Counter;

const console = terminal_kit.console;
const Printer = terminal_kit.printer.Printer;

const MiniLCG = terminal_kit.mini_lcg.MiniLCG;

const LinearMatrixPrinter = @import("../io/matrix_printer.zig").LinearMatrixPrinter;

const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;
const SymbolGenerator = @import("../domain/symbol.zig").SymbolGenerator;
const color = @import("../domain/color.zig");

/// Holds the resources and state required to render the matrix,
/// including its color scale, matrix data, and output formatter.
pub const RenderContext = struct {
    /// Color scale used to render the matrix symbols.
    scale: color.ColorScale,
    /// Matrix containing the data to be rendered.
    matrix: LinearMatrix,
    /// Handles the formatting and output of the matrix.
    matrixPrinter: LinearMatrixPrinter,

    /// Tracks the number of frames rendered and calculates the frame rate.
    counter: Counter,

    /// Initializes the rendering resources using the terminal dimensions
    /// and the provided configuration.
    ///
    /// Returns an error if initialization or matrix construction fails.
    pub fn init(
        self: *@This(),
        allocator: *std.mem.Allocator,
        winsize: console.WinSize,
        config: *const configuration.Configuration,
        printer: *Printer,
        lcg: *MiniLCG,
        asciiGenerator: *SymbolGenerator,
    ) !void {
        const space = calculate_padding(config);
        const isVertical = config.orientation == .vertical;

        const cols = if (isVertical)
            winsize.cols
        else
            winsize.rows - space;

        const rows = if (isVertical)
            winsize.rows - space
        else
            winsize.cols;

        const drop = calculate_drop_lenght(config, rows);

        self.scale = try color.ColorScale.init(
            allocator,
            drop,
            color.rgb_of(config.rainColor),
            config.rain_mode,
        );

        errdefer self.scale.free();

        self.matrix = LinearMatrix.init(
            allocator,
            lcg,
            asciiGenerator,
            &self.scale,
            config.matrix_mode,
        );

        errdefer self.matrix.free();

        try self.matrix.build(cols, rows);

        self.matrixPrinter = try LinearMatrixPrinter.init(
            allocator,
            printer,
            config.formatter,
            &self.scale,
            &self.matrix,
            isVertical,
        );

        errdefer self.matrixPrinter.free();

        self.counter = Counter.init();
    }

    /// Releases the resources owned by the rendering context.
    ///
    /// Must be called after successful initialization.
    pub fn deinit(self: *@This()) void {
        self.matrix.free();
        self.matrixPrinter.free();
        self.scale.free();
    }
};

inline fn calculate_padding(config: *const configuration.Configuration) usize {
    var space: usize = 0;
    if (config.debug) {
        space += 4;
    }

    if (config.controls) {
        space += 1;
    }

    return space;
}

inline fn calculate_drop_lenght(config: *const configuration.Configuration, rows: usize) usize {
    if (config.drop_len > 0) {
        return config.drop_len;
    }

    const f_rows: f32 = @floatFromInt(rows);
    return @intFromFloat(f_rows * config.drop_per);
}

test "calculate_padding returns zero when debug and controls are disabled" {
    const config = configuration.Configuration{
        .debug = false,
        .controls = false,
    };

    try std.testing.expectEqual(0, calculate_padding(&config));
}

test "calculate_padding reserves space for debug output" {
    const config = configuration.Configuration{
        .debug = true,
        .controls = false,
    };

    try std.testing.expectEqual(4, calculate_padding(&config));
}

test "calculate_padding reserves space for controls" {
    const config = configuration.Configuration{
        .debug = false,
        .controls = true,
    };

    try std.testing.expectEqual(1, calculate_padding(&config));
}

test "calculate_padding reserves space for debug output and controls" {
    const config = configuration.Configuration{
        .debug = true,
        .controls = true,
    };

    try std.testing.expectEqual(5, calculate_padding(&config));
}

test "calculate_drop_lenght uses the configured drop length" {
    const config = configuration.Configuration{
        .drop_len = 12,
        .drop_per = 0.5,
    };

    try std.testing.expectEqual(12, calculate_drop_lenght(&config, 20));
}

test "calculate_drop_lenght derives the length from the row count" {
    const config = configuration.Configuration{
        .drop_len = 0,
        .drop_per = 0.5,
    };

    try std.testing.expectEqual(10, calculate_drop_lenght(&config, 20));
}

test "calculate_drop_lenght returns zero for zero rows" {
    const config = configuration.Configuration{
        .drop_len = 0,
        .drop_per = 0.5,
    };

    try std.testing.expectEqual(0, calculate_drop_lenght(&config, 0));
}
