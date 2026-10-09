const std = @import("std");

const configuration = @import("configuration/configuration.zig");

const debug = @import("app/debug.zig");
const RenderContext = @import("app/render_context.zig").RenderContext;
const RuntimeState = @import("app/runtime_state.zig").RuntimeState;
const signals = @import("app/signals.zig");

const AllocatorTracer = @import("commons/allocator.zig").AllocatorTracer;
const MiniLCG = @import("commons/mini_lcg.zig").MiniLCG;

const console = @import("io/console.zig");
const Printer = @import("io/printer.zig").Printer;

const SymbolGenerator = @import("domain/symbol.zig").SymbolGenerator;

pub fn main() !void {
    var basePersistentAllocator = std.heap.page_allocator;
    var persistentAllocator = AllocatorTracer.init(&basePersistentAllocator);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var baseScratchAllocator = gpa.allocator();
    var scratchAllocator = AllocatorTracer.init(&baseScratchAllocator);

    var arena = std.heap.ArenaAllocator.init(scratchAllocator.allocator());
    defer arena.deinit();

    var printer = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer printer.reset();

    const config = try configuration.fromArgs(
        persistentAllocator.allocator(),
        &printer,
    );

    var state = RuntimeState{};

    state.start_timestamp.store(config.start_ms, .release);
    state.speed_ms.store(config.milliseconds, .release);

    try console.enableANSI();
    try console.enableUTF8();

    try console.enableRawMode();

    defer console.disableRawMode();

    try run(
        &state,
        &persistentAllocator,
        &scratchAllocator,
        &config,
        &printer,
    );
}

inline fn run(
    state: *RuntimeState,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
) !void {
    try signals.install(state, onInterrupt);

    var allocator = persistentAllocator.allocator();

    var lcg = MiniLCG.init(config.seed);

    var asciiGenerator = SymbolGenerator.init(
        &lcg,
        config.symbol_mode,
    );

    try printer.print(console.CLEAN_ALL);
    try printer.print(console.HIDE_CURSOR);

    defer printer.prints(console.SHOW_CURSOR);
    defer printer.prints(console.CLEAN_ALL);

    var input_thread = try std.Thread.spawn(
        .{},
        runInputLoop,
        .{state},
    );

    defer input_thread.join();

    while (!shouldExit(state)) {
        _ = state.consumeReload();

        try runRenderCycle(
            &allocator,
            persistentAllocator,
            scratchAllocator,
            state,
            config,
            printer,
            &lcg,
            &asciiGenerator,
        );
    }

    printer.reset();
}

inline fn runRenderCycle(
    allocator: *std.mem.Allocator,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    state: *RuntimeState,
    config: *const configuration.Configuration,
    printer: *Printer,
    lcg: *MiniLCG,
    asciiGenerator: *SymbolGenerator,
) !void {
    const winsize = try console.winSize();

    var context: RenderContext = undefined;

    try context.init(
        allocator,
        winsize,
        config,
        printer,
        lcg,
        asciiGenerator,
    );

    defer context.deinit();

    try printer.print(console.CLEAN_CONSOLE);

    while (!shouldExit(state) and !shouldReload(state)) {
        try printer.print(console.RESET_CURSOR);

        if (config.debug) {
            try debug.print_debug(
                state,
                persistentAllocator,
                scratchAllocator,
                config,
                printer,
                &context.matrix,
            );
        }

        try context.matrixPrinter.print(&context.matrix);

        if (!state.pause.load(.acquire)) {
            try context.matrix.next();
        }

        if (config.controls) {
            try debug.print_controls(printer);
        }

        const speed = state.speed_ms.load(.acquire);
        try state.waitForFrame(speed * std.time.ns_per_ms);

        printer.reset();

        const newWinsize = try console.winSize();
        if (winsize.cols != newWinsize.cols or winsize.rows != newWinsize.rows) {
            state.requestReload();
        }
    }
}

fn runInputLoop(state: *RuntimeState) !void {
    const stdin = std.fs.File.stdin();

    while (!shouldExit(state)) {
        var buf: [1]u8 = undefined;

        const count = try stdin.read(&buf);
        if (count == 0) {
            continue;
        }

        switch (buf[0]) {
            'p', 'P', console.SPACE => {
                state.togglePause();
            },
            '+' => {
                const speed = state.speed_ms.load(.acquire);
                const min = @min(3000, speed + 10);
                state.setSpeed(min);
            },
            '-' => {
                const speed = state.speed_ms.load(.acquire);
                const max = speed -| 10;
                state.setSpeed(max);
            },
            'q', 'Q', console.CTRL_C => {
                state.requestExit();
            },
            else => {},
        }
    }
}

fn onInterrupt(context: *anyopaque) void {
    const state: *RuntimeState = @ptrCast(@alignCast(context));
    state.requestExit();
}

fn shouldExit(state: *const RuntimeState) bool {
    return state.exit.load(.acquire);
}

fn shouldReload(state: *const RuntimeState) bool {
    return state.reload.load(.acquire);
}
