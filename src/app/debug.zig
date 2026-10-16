const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const Printer = terminal_kit.printer.Printer;

const configuration = @import("../configuration/configuration.zig");

const RenderContext = @import("./render_context.zig").RenderContext;

/// Prints diagnostic information about the application, runtime state,
/// memory usage, rendering configuration, and current matrix dimensions.
///
/// Returns an error if memory allocation, time formatting, or printing fails.
pub fn print_debug(
    state: *RuntimeState,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    context: *RenderContext,
) !void {
    var scratch = scratchAllocator.allocator();

    var matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const fixedArea = rows * cols;

    var end_ms = std.time.milliTimestamp();
    if (state.pause.load(.acquire)) {
        end_ms = state.pause_timestamp.load(.acquire);
    }

    const start_timestamp = state.start_timestamp.load(.acquire);
    const time = try kit_time.milliseconds_to_time(scratch, end_ms - start_timestamp, null);
    defer scratch.free(time);

    var paused = false;
    if (state.pause.load(.acquire)) {
        paused = true;
    }

    try printer.printf("{}: {s}\n", .{
        build.name,
        build.version,
    });

    try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes | Paused: {any} | FPS: {d} \n", .{
        persistentAllocator.bytes(),
        scratchAllocator.bytes(),
        paused,
        context.counter.get_frame_rate(std.time.ms_per_s),
    });

    try printer.printf("Speed: {d}ms | Ascii: {any} | Rain: {any} | Mode: {any} | Formatter: {any} | Orientation: {any}\n", .{
        state.speed_ms.load(.acquire),
        config.symbol_mode,
        config.rainColor,
        config.matrix_mode,
        config.formatter.code(),
        config.orientation,
    });

    try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Drop lenght: {d} | Time: {s} \n", .{
        config.seed,
        fixedArea,
        cols,
        rows,
        config.drop_len,
        time,
    });
}

/// Prints the keyboard shortcuts available to control the application.
///
/// Returns an error if printing the controls fails.
pub fn print_controls(printer: *Printer) !void {
    try printer.printf("\nPause: [{s}] | Increment sleep: [{s}] | Decrement sleep: [{s}] | Exit: [{s}]", .{
        "p, space",
        "+",
        "-",
        "q, ctrl+c",
    });
}
