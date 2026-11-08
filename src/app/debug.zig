const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

const console = terminal_kit.console;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const Printer = terminal_kit.printer.Printer;

const GameState = @import("./game_state.zig").GameState;

const configuration = @import("../configuration/configuration.zig");

const RenderContext = @import("./render_context.zig").RenderContext;

const Flux = @import("../domain/flux.zig").Flux;
const Orientation = @import("../domain/orientation.zig").Orientation;

/// Prints diagnostic information about the application, runtime state,
/// memory usage, rendering configuration, and current matrix dimensions.
///
/// Returns an error if memory allocation, time formatting, or printing fails.
pub fn print_debug(
    state: *RuntimeState,
    persistent: *AllocatorTracer,
    scratch: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    context: *RenderContext,
    target_cursor: usize,
) !usize {
    const allocator = scratch.allocator();

    var matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const area = rows * cols;

    const time = try kit_time.milliseconds_to_time(allocator, state.get_runtime(), null);
    defer allocator.free(time);

    const drop_len = if (config.drop_len == 0)
        try printer.format("{d}%", .{config.drop_per})
    else
        try printer.format("{d}", .{config.drop_len});

    const orientation: Orientation = if (context.matrix_printer.vertical)
        .vertical
    else
        .horizontal;

    const flux: Flux = if (context.matrix_printer.reverse)
        .reverse
    else
        .normal;

    var max_cursor: usize = 0;

    const header = try printer.format_limited(
        target_cursor,
        cols,
        "{}: {s}",
        .{
            build.name,
            build.version,
        },
    );

    max_cursor = header.max_cursor;

    const memory = try printer.format_limited(
        target_cursor,
        cols,
        "Persistent memory: {d} bytes | " ++
            "Scratch memory: {d} bytes | " ++
            "Paused: {any} | " ++
            "FPS: {d}",
        .{
            persistent.bytes(),
            scratch.bytes(),
            state.is_paused(),
            context.counter.get_frame_rate(std.time.ms_per_s),
        },
    );

    max_cursor = @max(max_cursor, memory.max_cursor);

    const runtime_1 = try printer.format_limited(
        target_cursor,
        cols,
        "Speed: {d}ms | " ++
            "Ascii: {any} | " ++
            "Rain: {any} | " ++
            "Mode: {any} | " ++
            "Formatter: {any} | " ++
            "Orientation: {any} | " ++
            "Flux: {any}",
        .{
            state.get_speed(),
            config.symbol_mode,
            config.rain_color,
            config.matrix_mode,
            config.color_mode,
            orientation,
            flux,
        },
    );

    max_cursor = @max(max_cursor, runtime_1.max_cursor);

    const runtime_2 = try printer.format_limited(
        target_cursor,
        cols,
        "Seed: {d} | " ++
            "Matrix: {d} | " ++
            "Columns: {d} | " ++
            "Rows: {d} | " ++
            "Drop length: {d} | " ++
            "Drain: {any} | " ++
            "Time: {s}",
        .{
            config.seed,
            area,
            cols,
            rows,
            config.drop_len,
            matrix.pause_requested,
            time,
        },
    );

    max_cursor = @max(max_cursor, runtime_2.max_cursor);

    try printer.printf(
        "{s}{s}\n" ++
            "{s}{s}\n" ++
            "{s}{s}\n" ++
            "{s}{s}\n",
        .{
            console.CLEAN_LINE,
            header.text,
            console.CLEAN_LINE,
            memory.text,
            console.CLEAN_LINE,
            runtime_1.text,
            console.CLEAN_LINE,
            runtime_2.text,
        },
    );

    return @max(max_cursor, runtime_2.max_cursor);
}

/// Prints the keyboard shortcuts available to control the application.
///
/// Returns an error if printing the controls fails.
pub fn print_controls(
    printer: *Printer,
    context: *RenderContext,
    target_cursor: usize,
) !usize {
    const matrix = context.matrix;
    const cols = matrix.cols_len();

    var max_cursor: usize = 0;

    const app_controls = try printer.format_limited(
        target_cursor,
        cols,
        "Pause: [{s}] | " ++
            "Inc sleep: [{s}] | " ++
            "Dec sleep: [{s}] | " ++
            "Drain: [{s}] | " ++
            "Orientation: [{s}] | " ++
            "Flux: [{s}]",
        .{
            "p, space",
            "+",
            "-",
            "d",
            "o",
            "f",
        },
    );

    max_cursor = app_controls.max_cursor;

    const trm_controls = try printer.format_limited(
        target_cursor,
        cols,
        "Scroll left: [{s}] | " ++
            "Scroll right: [{s}] | " ++
            "Show debug: [{s}] | " ++
            "Show controls: [{s}] | " ++
            "Exit: [{s}]",
        .{
            ",",
            ".",
            "/",
            "?",
            "q, ctrl+c",
        },
    );

    try printer.printf(
        "\n{s}{s}" ++
            "\n{s}{s}",
        .{
            console.CLEAN_LINE,
            app_controls.text,
            console.CLEAN_LINE,
            trm_controls.text,
        },
    );

    return @max(max_cursor, trm_controls.max_cursor);
}
