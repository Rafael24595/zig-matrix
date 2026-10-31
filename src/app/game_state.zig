const std = @import("std");

const math = std.math;

const testing = std.testing;

const Orientation = @import("../domain/orientation.zig").Orientation;
const Flux = @import("../domain/flux.zig").Flux;

/// Represents the current state of the game, including whether a drain has been requested.
pub const GameState = struct {
    /// Indicates whether a drain has been requested.
    drain_requested: std.atomic.Value(bool) = .init(false),
    /// Indicates whether a flux has been requested.
    flux_requested: std.atomic.Value(bool) = .init(false),

    /// Indicates the current orientation of the game (vertical or horizontal).
    orientation: std.atomic.Value(Orientation) = .init(.vertical),
    /// Indicates the current flux state of the game (normal or reverse).
    flux: std.atomic.Value(Flux) = .init(.normal),

    /// Requests a drain, setting the drain flag to true.
    pub fn request_drain(self: *@This()) void {
        self.drain_requested.store(true, .release);
    }

    /// Consumes the drain request, returning true if a drain was requested and resetting the flag to false.
    pub fn consume_drain(self: *@This()) bool {
        return self.drain_requested.swap(false, .acq_rel);
    }

    /// Requests a flux, setting the flux flag to true.
    pub fn request_flux(self: *@This()) void {
        self.flux_requested.store(true, .release);
    }

    /// Consumes the flux request, returning true if a flux was requested and resetting the flag to false.
    pub fn consume_flux(self: *@This()) bool {
        return self.flux_requested.swap(false, .acq_rel);
    }

    /// Toggles the orientation between vertical and horizontal.
    pub fn toggle_orientation(self: *@This()) void {
        const last = self.orientation.load(.acquire);

        const orientation: Orientation = if (last == .vertical)
            .horizontal
        else
            .vertical;

        self.orientation.store(orientation, .release);
    }

    /// Toggles the flux state between normal and reverse.
    pub fn toggle_flux(self: *@This()) void {
        const last = self.flux.load(.acquire);

        const flux: Flux = if (last == .normal)
            .reverse
        else
            .normal;

        self.flux.store(flux, .release);
    }
};

test "GameState initial state is false" {
    var state = GameState{};
    try std.testing.expect(!state.drain_requested.load(.monotonic));
    try std.testing.expect(!state.flux_requested.load(.monotonic));
}

test "request_drain sets drain to true" {
    var state = GameState{};
    state.request_drain();

    try std.testing.expect(state.drain_requested.load(.monotonic));
}

test "consume_drain returns false when not requested and keeps it false" {
    var state = GameState{};

    const consumed = state.consume_drain();

    try std.testing.expect(!consumed);
    try std.testing.expect(!state.drain_requested.load(.monotonic));
}

test "consume_drain returns true when requested and resets flag to false" {
    var state = GameState{};
    state.request_drain();

    const consumed = state.consume_drain();

    try std.testing.expect(consumed);
    try std.testing.expect(!state.drain_requested.load(.monotonic));
    try std.testing.expect(!state.consume_drain());
}

test "request_flux sets flux to true" {
    var state = GameState{};
    state.request_flux();

    try std.testing.expect(state.flux_requested.load(.monotonic));
}

test "consume_flux returns false when not requested and keeps it false" {
    var state = GameState{};

    const consumed = state.consume_flux();

    try std.testing.expect(!consumed);
    try std.testing.expect(!state.flux_requested.load(.monotonic));
}

test "consume_flux returns true when requested and resets flag to false" {
    var state = GameState{};
    state.request_flux();

    const consumed = state.consume_flux();

    try std.testing.expect(consumed);
    try std.testing.expect(!state.flux_requested.load(.monotonic));
    try std.testing.expect(!state.consume_flux());
}

test "GameState initial orientation and flux are vertical and normal" {
    const state = GameState{};

    try testing.expectEqual(
        Orientation.vertical,
        state.orientation.load(.monotonic),
    );
    try testing.expectEqual(
        Flux.normal,
        state.flux.load(.monotonic),
    );
}

test "toggle_orientation alternates between vertical and horizontal" {
    var state = GameState{};

    state.toggle_orientation();
    try testing.expectEqual(
        Orientation.horizontal,
        state.orientation.load(.monotonic),
    );

    state.toggle_orientation();
    try testing.expectEqual(
        Orientation.vertical,
        state.orientation.load(.monotonic),
    );
}

test "toggle_flux alternates between normal and reverse" {
    var state = GameState{};

    state.toggle_flux();
    try testing.expectEqual(
        Flux.reverse,
        state.flux.load(.monotonic),
    );

    state.toggle_flux();
    try testing.expectEqual(
        Flux.normal,
        state.flux.load(.monotonic),
    );
}

test "multiple drain requests are coalesced into one" {
    var state = GameState{};

    state.request_drain();
    state.request_drain();

    try testing.expect(state.consume_drain());
    try testing.expect(!state.consume_drain());
}
