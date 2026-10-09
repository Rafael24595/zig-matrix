const std = @import("std");

const build = @import("build.zig.zon");

const utils = @import("../commons/utils.zig");
const AllocatorTracer = @import("../commons/allocator.zig").AllocatorTracer;

const RuntimeState = @import("./runtime_state.zig").RuntimeState;
const configuration = @import("../configuration/configuration.zig");

const Printer = @import("../io/printer.zig").Printer;
const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;

pub fn print_debug(
    state: *RuntimeState,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    matrix: *LinearMatrix,
) !void {
    var scratch = scratchAllocator.allocator();

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const fixedArea = rows * cols;

    var end_ms = std.time.milliTimestamp();
    if (state.pause.load(.acquire)) {
        end_ms = state.pause_timestamp.load(.acquire);
    }

    const start_timestamp = state.start_timestamp.load(.acquire);
    const time = try utils.millisecondsToTime(scratch, end_ms - start_timestamp, null);
    defer scratch.free(time);

    var paused = false;
    if (state.pause.load(.acquire)) {
        paused = true;
    }

    try printer.printf("{}: {s}\n", .{
        build.name,
        build.version,
    });

    try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes | Paused {any} \n", .{
        persistentAllocator.bytes(),
        scratchAllocator.bytes(),
        paused,
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

pub fn print_controls(
    printer: *Printer,
) !void {
    try printer.printf("\nPause: [{s}] | Increment sleep: [{s}] | Decrement sleep: [{s}] | Exit: [{s}]", .{
        "p, space",
        "+",
        "-",
        "q, ctrl+c",
    });
}
