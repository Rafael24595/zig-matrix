const std = @import("std");

const math = std.math;

const testing = std.testing;

const Orientation = @import("../domain/orientation.zig").Orientation;
const Direction = @import("../domain/direction.zig").Direction;

/// Represents the current state of the game, including whether a drain has been requested.
pub const GameState = struct {
    /// Indicates whether a drain has been requested.
    drain_requested: std.atomic.Value(bool) = .init(false),
    /// Indicates whether a direction has been requested.
    direction_requested: std.atomic.Value(bool) = .init(false),

    /// Indicates the current orientation of the game (vertical or horizontal).
    orientation: std.atomic.Value(Orientation) = .init(.vertical),
    /// Indicates the current direction state of the game (normal or reverse).
    direction: std.atomic.Value(Direction) = .init(.normal),

    /// Initializes a new GameState with the specified orientation and direction.
    /// The drain and direction request flags are initialized to false.
    pub fn init(
        orientation: Orientation,
        direction: Direction,
    ) @This() {
        return .{
            .orientation = .init(orientation),
            .direction = .init(direction),
        };
    }

    /// Requests a drain, setting the drain flag to true.
    pub fn request_drain(self: *@This()) void {
        self.drain_requested.store(true, .release);
    }

    /// Consumes the drain request, returning true if a drain was requested and resetting the flag to false.
    pub fn consume_drain(self: *@This()) bool {
        return self.drain_requested.swap(false, .acq_rel);
    }

    /// Returns the current direction state of the game (normal or reverse).
    pub fn get_direction(self: @This()) Direction {
        return self.direction.load(.acquire);
    }

    /// Requests a direction, setting the direction flag to true.
    pub fn request_direction(self: *@This()) void {
        self.direction_requested.store(true, .release);
    }

    /// Consumes the direction request, returning true if a direction was requested and resetting the flag to false.
    pub fn consume_direction(self: *@This()) bool {
        return self.direction_requested.swap(false, .acq_rel);
    }

    /// Toggles the direction state between normal and reverse.
    pub fn toggle_direction(self: *@This()) void {
        const last = self.direction.load(.acquire);

        const direction: Direction = if (last == .normal)
            .reverse
        else
            .normal;

        self.direction.store(direction, .release);
    }

    /// Returns the current orientation of the game (vertical or horizontal).
    pub fn get_orientation(self: @This()) Orientation {
        return self.orientation.load(.acquire);
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

test "request_direction sets direction to true" {
    var state = GameState{};
    state.request_direction();

    try std.testing.expect(state.direction_requested.load(.monotonic));
}

test "consume_direction returns false when not requested and keeps it false" {
    var state = GameState{};

    const consumed = state.consume_direction();

    try std.testing.expect(!consumed);
    try std.testing.expect(!state.direction_requested.load(.monotonic));
}

test "consume_direction returns true when requested and resets flag to false" {
    var state = GameState{};
    state.request_direction();

    const consumed = state.consume_direction();

    try std.testing.expect(consumed);
    try std.testing.expect(!state.direction_requested.load(.monotonic));
    try std.testing.expect(!state.consume_direction());
}

test "GameState initial orientation and direction are vertical and normal" {
    const state = GameState{};

    try testing.expectEqual(
        .vertical,
        state.orientation.load(.monotonic),
    );
    try testing.expectEqual(
        .normal,
        state.direction.load(.monotonic),
    );
}

test "toggle_orientation alternates between vertical and horizontal" {
    var state = GameState{};

    state.toggle_orientation();
    try testing.expectEqual(
        .horizontal,
        state.orientation.load(.monotonic),
    );

    state.toggle_orientation();
    try testing.expectEqual(
        .vertical,
        state.orientation.load(.monotonic),
    );
}

test "toggle_direction alternates between normal and reverse" {
    var state = GameState{};

    state.toggle_direction();
    try testing.expectEqual(
        .reverse,
        state.direction.load(.monotonic),
    );

    state.toggle_direction();
    try testing.expectEqual(
        .normal,
        state.direction.load(.monotonic),
    );
}

test "multiple drain requests are coalesced into one" {
    var state = GameState{};

    state.request_drain();
    state.request_drain();

    try testing.expect(state.consume_drain());
    try testing.expect(!state.consume_drain());
}
