const std = @import("std");
const builtin = @import("builtin");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const Printer = terminal_kit.printer.Printer;

const Flag = terminal_kit.configuration.Flag;
const kit_conf = terminal_kit.configuration;

const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

const matrix = @import("../domain/matrix.zig");
const orientation = @import("../domain/orientation.zig");

const formatter = @import("../io/formatter.zig");

const frame_pause_ms: u64 = switch (builtin.os.tag) {
    .windows => 55,
    else => 65,
};

const FLAG_HELP: Flag = Flag{
    .flag_short = "-h",
    .flag_long = "--help",
    .desc = "Show this help message",
    .name = "help",
};

const FLAG_VERSION: Flag = Flag{
    .flag_short = "-v",
    .flag_long = "--version",
    .desc = "Show project's version",
    .name = "version",
};

const FLAG_DEBUG: Flag = Flag{
    .flag_short = "-d",
    .flag_long = "",
    .desc = "Enable debug mode",
    .name = "debug",
};

const FLAG_HELP_CONTROLS: Flag = Flag{
    .flag_short = "-hc",
    .desc = "Show the controls map",
    .name = "controls map",
};

const FLAG_SEED: Flag = Flag{
    .flag_short = "-s",
    .type = "<number>",
    .desc = "Random seed",
    .name = "seed",
};

const FLAG_MILLISECONDS: Flag = Flag{
    .flag_short = "-ms",
    .type = "<number>",
    .desc = "Frame delay in ms",
    .name = "milliseconds",
};

const FLAG_DROP_LENGTH: Flag = Flag{
    .flag_short = "-l",
    .type = "<number>",
    .desc = "Drop length",
    .name = "drop`length",
};

const FLAG_THEME_COLOR: Flag = Flag{
    .flag_short = "-tc",
    .type = "<enum>",
    .desc = "Theme color",
    .name = "theme color",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_THEME_GRADIENT: Flag = Flag{
    .flag_short = "-tg",
    .type = "<enum>",
    .desc = "Theme gradient",
    .name = "theme gradient",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_THEME_SYMBOL: Flag = Flag{
    .flag_short = "-ts",
    .type = "<enum>",
    .desc = "Theme symbol",
    .name = "Theme symbol",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_MATRIX_MODE: Flag = Flag{
    .flag_short = "-mm",
    .type = "<enum>",
    .desc = "Matrix mode",
    .name = "matrix mode",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_COLOR_MODE: Flag = Flag{
    .flag_short = "-cm",
    .type = "<enum>",
    .desc = "Color color",
    .name = "color color",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_ORIENTATION_MODE: Flag = Flag{
    .flag_short = "-o",
    .type = "<enum>",
    .desc = "Matrix orientation",
    .name = "orientation",
    .aux_desc = "(vertical or horizontal)",
};

/// Stores the application settings parsed from command-line arguments,
/// including rendering options, animation timing, and matrix appearance.
pub const Configuration = struct {
    /// Enables diagnostic information during execution.
    debug: bool = false,
    /// Enables the display of keyboard controls.
    controls: bool = false,

    /// Random seed used to initialize the matrix generation.
    /// A value of zero causes the seed to be derived from the current timestamp.
    seed: u64 = 0,

    /// Application start timestamp, in milliseconds since the Unix epoch.
    start_ms: i64 = 0,

    /// Delay between animation frames, in milliseconds.
    milliseconds: u64 = frame_pause_ms,

    /// Drop length as a proportion of the matrix height when `drop_len` is zero.
    drop_per: f32 = 0.4,
    /// Explicit drop length. A value of zero enables automatic calculation.
    drop_len: usize = 0,

    /// Base color used for the rain effect.
    rainColor: color.Color = .green,
    /// Gradient applied to the rain effect.
    rain_mode: color.ThemeGradient = .default,
    /// Theme used to generate matrix symbols.
    symbol_mode: symbol.Theme = .default,
    /// Behavior used to generate matrix contents.
    matrix_mode: matrix.Mode = .rain,

    /// Formatter used to produce the matrix colors.
    formatter: formatter.FormatterUnion = formatter.FormatterUnion{ .rgb = .{} },

    /// Direction in which the matrix is rendered.
    orientation: orientation.Orientation = .vertical,

    /// Parses command-line arguments into a configuration.
    ///
    /// Uses `allocator` for temporary allocations and `printer` for
    /// formatting or reporting command-line information.
    /// Exits the process for help, version, or unknown arguments.
    pub fn init(allocator: std.mem.Allocator, printer: *Printer, args: [][:0]u8) !@This() {
        defer printer.reset();

        var config = Configuration{};

        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, FLAG_HELP.flag_short) or std.mem.eql(u8, arg, FLAG_HELP.flag_long.?)) {
                try print_help(allocator, printer, config);
                std.process.exit(0);
            }

            if (std.mem.eql(u8, arg, FLAG_VERSION.flag_short) or std.mem.eql(u8, arg, FLAG_VERSION.flag_long.?)) {
                try printer.printf("{any}: {s}\n", .{ build.name, build.version });
                std.process.exit(0);
            }

            if (std.mem.eql(u8, arg, FLAG_DEBUG.flag_short)) {
                config.debug = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_HELP_CONTROLS.flag_short)) {
                config.controls = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_SEED.flag_short)) {
                config.seed = try kit_conf.parse_int(u64, printer, args, i, FLAG_SEED, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MILLISECONDS.flag_short)) {
                config.milliseconds = try kit_conf.parse_int(u64, printer, args, i, FLAG_MILLISECONDS, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_DROP_LENGTH.flag_short)) {
                config.drop_len = try kit_conf.parse_int(u64, printer, args, i, FLAG_DROP_LENGTH, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_COLOR.flag_short)) {
                config.rainColor = try kit_conf.parse_enum(color.Color, printer, args, i, FLAG_THEME_COLOR);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_GRADIENT.flag_short)) {
                config.rain_mode = try kit_conf.parse_enum(color.ThemeGradient, printer, args, i, FLAG_THEME_GRADIENT);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_SYMBOL.flag_short)) {
                config.symbol_mode = try kit_conf.parse_enum(symbol.Theme, printer, args, i, FLAG_THEME_SYMBOL);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MATRIX_MODE.flag_short)) {
                config.matrix_mode = try kit_conf.parse_enum(matrix.Mode, printer, args, i, FLAG_MATRIX_MODE);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_COLOR_MODE.flag_short)) {
                const code = try kit_conf.parse_enum(formatter.FormatterCode, printer, args, i, FLAG_COLOR_MODE);
                config.formatter = formatter.union_of(code);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_ORIENTATION_MODE.flag_short)) {
                config.orientation = try kit_conf.parse_enum(orientation.Orientation, printer, args, i, FLAG_ORIENTATION_MODE);
                i += 1;
                continue;
            }

            try printer.printf("Unknown argument: {s}\n", .{arg});
            std.process.exit(1);
        }

        const timestamp = std.time.milliTimestamp();

        config.start_ms = timestamp;

        if (config.seed == 0) {
            config.seed = @intCast(timestamp);
        }

        return config;
    }

    inline fn print_help(
        allocator: std.mem.Allocator,
        printer: *Printer,
        config: Configuration,
    ) !void {
        const message = try format_flags(allocator, printer, config);
        defer allocator.free(message);
        try printer.print(message);
    }

    inline fn format_flags(
        allocator: std.mem.Allocator,
        printer: *Printer,
        config: Configuration,
    ) ![]u8 {
        var buffer = try std.ArrayList(u8).initCapacity(allocator, 0);

        const drop_default = try printer.format(
            "{d:.2} x matrix height",
            .{config.drop_per},
        );

        try buffer.appendSlice(allocator, "\nUsage: zig-matrix             [options] \n\n");

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_HELP,
            .none,
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_VERSION,
            .none,
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_DEBUG,
            .{ .bool = config.debug },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_HELP_CONTROLS,
            .{ .bool = config.controls },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_SEED,
            .{ .str = "current time in ms" },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_MILLISECONDS,
            .{ .int = @intCast(config.milliseconds) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_DROP_LENGTH,
            .{ .str = drop_default },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_THEME_COLOR,
            .{ .str = @tagName(config.rainColor) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_THEME_GRADIENT,
            .{ .str = @tagName(config.rain_mode) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_THEME_SYMBOL,
            .{ .str = @tagName(config.symbol_mode) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_MATRIX_MODE,
            .{ .str = @tagName(config.matrix_mode) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_COLOR_MODE,
            .{ .str = @tagName(config.formatter.code()) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_ORIENTATION_MODE,
            .{ .str = @tagName(config.orientation) },
        ));

        return buffer.items;
    }
};

/// Builds the application configuration from the current process arguments.
///
/// Allocates the argument list using `allocator` and releases it before
/// returning. Propagates errors from argument allocation and parsing.
pub fn from_args(allocator: std.mem.Allocator, printer: *Printer) !Configuration {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    return Configuration.init(allocator, printer, args);
}

test "Configuration uses the expected default values" {
    const config = Configuration{};

    try std.testing.expect(!config.debug);
    try std.testing.expect(!config.controls);

    try std.testing.expectEqual(@as(u64, 0), config.seed);
    try std.testing.expectEqual(@as(i64, 0), config.start_ms);
    try std.testing.expectEqual(frame_pause_ms, config.milliseconds);

    try std.testing.expectEqual(@as(f32, 0.4), config.drop_per);
    try std.testing.expectEqual(@as(usize, 0), config.drop_len);

    try std.testing.expectEqual(color.Color.green, config.rainColor);
    try std.testing.expectEqual(color.ThemeGradient.default, config.rain_mode);
    try std.testing.expectEqual(symbol.Theme.default, config.symbol_mode);
    try std.testing.expectEqual(matrix.Mode.rain, config.matrix_mode);
    try std.testing.expectEqual(orientation.Orientation.vertical, config.orientation);

    try std.testing.expectEqual(formatter.FormatterCode.rgb, config.formatter.code());
}
