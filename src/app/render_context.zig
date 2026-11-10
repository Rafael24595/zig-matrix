const std = @import("std");

const terminal_kit = @import("terminal_kit");

const Counter = terminal_kit.frame.Counter;

const console = terminal_kit.console;
const clock = terminal_kit.clock;

const Printer = terminal_kit.printer.Printer;
const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const SplitMix64 = terminal_kit.splitmix64.SplitMix64;

const kit_color = terminal_kit.color;

const GameState = @import("./game_state.zig").GameState;

const configuration = @import("../configuration/configuration.zig");

const LinearMatrixPrinter = @import("../io/matrix_printer.zig").LinearMatrixPrinter;

const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;
const SymbolGenerator = @import("../domain/symbol.zig").SymbolGenerator;
const color = @import("../domain/color.zig");

/// Holds the resources and state required to render the matrix,
/// including its color scale, matrix data, output formatter and frame counter.
///
/// Call `init` before using the context and `deinit` to release its
/// resources after successful initialization.
pub const RenderContext = struct {
    /// Color scale used to render the matrix symbols.
    scale: color.ColorScale,
    /// Matrix containing the data to be rendered.
    matrix: LinearMatrix,
    /// Handles the formatting and output of the matrix.
    matrix_printer: LinearMatrixPrinter,

    /// Tracks the number of frames rendered and calculates the frame rate.
    counter: Counter,

    /// Initializes the rendering resources using the terminal dimensions
    /// and the provided configuration.
    ///
    /// Returns an error if initialization or matrix construction fails.
    pub fn init(
        self: *@This(),
        allocator: std.mem.Allocator,
        winsize: console.WinSize,
        config: *const configuration.Configuration,
        state: *RuntimeState,
        game_state: *GameState,
        printer: *Printer,
        rng: *SplitMix64,
        generator: *SymbolGenerator,
    ) !void {
        const space = calculate_padding(state);

        const vertical = game_state.get_orientation() == .vertical;
        const reverse = game_state.get_flux() == .reverse;

        const cols = if (vertical)
            winsize.cols
        else
            winsize.rows - space;

        const rows = if (vertical)
            winsize.rows - space
        else
            winsize.cols;

        const drop = calculate_drop_lenght(config, rows);

        self.scale = try color.ColorScale.init(
            allocator,
            drop,
            kit_color.rgb_of(config.rain_color),
            config.rain_mode,
        );

        errdefer self.scale.free();

        self.matrix = LinearMatrix.init(
            allocator,
            rng,
            generator,
            &self.scale,
            config.matrix_mode,
        );

        errdefer self.matrix.free();

        try self.matrix.build(cols, rows);

        self.matrix_printer = try LinearMatrixPrinter.init(
            allocator,
            printer,
            config.formatter_matrix,
            config.formatter_cell,
            &self.scale,
            &self.matrix,
            vertical,
            reverse,
        );

        errdefer self.matrix_printer.free();

        self.counter = Counter.init(config.clock);
    }

    /// Releases the resources owned by the rendering context.
    ///
    /// Must be called after successful initialization.
    pub fn deinit(self: *@This()) void {
        self.matrix.free();
        self.matrix_printer.free();
        self.scale.free();
    }
};

inline fn calculate_padding(state: *RuntimeState) usize {
    var space: usize = 0;
    if (state.show_debug()) {
        space += 4;
    }

    if (state.show_controls()) {
        space += 2;
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
    var state = RuntimeState{
        .clock = clock.system_clock,
        .debug = .init(false),
        .controls = .init(false),
    };

    try std.testing.expectEqual(0, calculate_padding(&state));
}

test "calculate_padding reserves space for debug output" {
    var state = RuntimeState{
        .clock = clock.system_clock,
        .debug = .init(true),
        .controls = .init(false),
    };

    try std.testing.expectEqual(4, calculate_padding(&state));
}

test "calculate_padding reserves space for controls" {
    var state = RuntimeState{
        .clock = clock.system_clock,
        .debug = .init(false),
        .controls = .init(true),
    };

    try std.testing.expectEqual(2, calculate_padding(&state));
}

test "calculate_padding reserves space for debug output and controls" {
    var state = RuntimeState{
        .clock = clock.system_clock,
        .debug = .init(true),
        .controls = .init(true),
    };

    try std.testing.expectEqual(6, calculate_padding(&state));
}

test "calculate_drop_lenght uses the configured drop length" {
    const config = configuration.Configuration{
        .clock = clock.system_clock,
        .drop_len = 12,
        .drop_per = 0.5,
    };

    try std.testing.expectEqual(12, calculate_drop_lenght(&config, 20));
}

test "calculate_drop_lenght derives the length from the row count" {
    const config = configuration.Configuration{
        .clock = clock.system_clock,
        .drop_len = 0,
        .drop_per = 0.5,
    };

    try std.testing.expectEqual(10, calculate_drop_lenght(&config, 20));
}

test "calculate_drop_lenght returns zero for zero rows" {
    const config = configuration.Configuration{
        .clock = clock.system_clock,
        .drop_len = 0,
        .drop_per = 0.5,
    };

    try std.testing.expectEqual(0, calculate_drop_lenght(&config, 0));
}
