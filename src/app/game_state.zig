const std = @import("std");

const math = std.math;

const testing = std.testing;

/// Represents the current state of the game, including whether a drain has been requested.
pub const GameState = struct {
    /// Indicates whether a drain has been requested.
    drain: std.atomic.Value(bool) = .init(false),

    /// Requests a drain, setting the drain flag to true.
    pub fn request_drain(self: *@This()) void {
        self.drain.store(true, .release);
    }

    /// Consumes the drain request, returning true if a drain was requested and resetting the flag to false.
    pub fn consume_drain(self: *@This()) bool {
        return self.drain.swap(false, .acq_rel);
    }
};

test "GameState initial state is false" {
    var state = GameState{};
    try std.testing.expect(!state.drain.load(.monotonic));
}

test "request_drain sets drain to true" {
    var state = GameState{};
    state.request_drain();

    try std.testing.expect(state.drain.load(.monotonic));
}

test "consume_drain returns false when not requested and keeps it false" {
    var state = GameState{};

    const consumed = state.consume_drain();

    try std.testing.expect(!consumed);
    try std.testing.expect(!state.drain.load(.monotonic));
}

test "consume_drain returns true when requested and resets flag to false" {
    var state = GameState{};
    state.request_drain();

    const consumed = state.consume_drain();

    try std.testing.expect(consumed);
    try std.testing.expect(!state.drain.load(.monotonic));
    try std.testing.expect(!state.consume_drain());
}
