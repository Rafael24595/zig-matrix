const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

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
) !void {
    var allocator = scratch.allocator();

    var matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const area = rows * cols;

    var end_ms = std.time.milliTimestamp();
    if (state.pause.load(.acquire)) {
        end_ms = state.pause_timestamp.load(.acquire);
    }

    const start_timestamp = state.start_timestamp.load(.acquire);

    const time = try kit_time.milliseconds_to_time(allocator, end_ms - start_timestamp, null);
    defer allocator.free(time);

    const paused = state.pause.load(.acquire);

    const orientation: Orientation = if (context.matrix_printer.vertical)
        .vertical
    else
        .horizontal;

    const flux: Flux = if (context.matrix_printer.reverse)
        .reverse
    else
        .normal;

    try printer.printf("{}: {s} \n", .{
        build.name,
        build.version,
    });

    try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes | Paused: {any} | FPS: {d} \n", .{
        persistent.bytes(),
        scratch.bytes(),
        paused,
        context.counter.get_frame_rate(std.time.ms_per_s),
    });

    try printer.printf("Speed: {d}ms | Ascii: {any} | Rain: {any} | Mode: {any} | Formatter: {any} | Orientation: {any} | Flux: {any} \n", .{
        state.speed_ms.load(.acquire),
        config.symbol_mode,
        config.rain_color,
        config.matrix_mode,
        config.color_mode,
        orientation,
        flux,
    });

    try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Drop length: {d} | Drain: {any} | Time: {s} \n", .{
        config.seed,
        area,
        cols,
        rows,
        config.drop_len,
        matrix.pause_requested,
        time,
    });
}

/// Prints the keyboard shortcuts available to control the application.
///
/// Returns an error if printing the controls fails.
pub fn print_controls(printer: *Printer) !void {
    try printer.printf("\nPause: [{s}] | Increment sleep: [{s}] | Decrement sleep: [{s}] | Drain: [{s}] | Orientation: [{s}] | Flux: [{s}] | Exit: [{s}]", .{
        "p, space",
        "+",
        "-",
        "d",
        "o",
        "f",
        "q, ctrl+c",
    });
}
