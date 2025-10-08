const std = @import("std");

const color = @import("root.zig").color;

test "correct RGB values for known colors" {
    try std.testing.expectEqual([3]u8{255, 0, 0}, color.rgbOf(color.Color.Red));
    try std.testing.expectEqual([3]u8{0, 255, 0}, color.rgbOf(color.Color.Green));
    try std.testing.expectEqual([3]u8{0, 0, 255}, color.rgbOf(color.Color.Blue));
}

test "init creates map with correct length" {
    var allocator = std.testing.allocator;
    const base = [3]u8{128, 128, 128};
    var scale = try color.ColorScale.init(&allocator, 10, base, color.Mode.Linear);
    defer scale.free();

    try std.testing.expectEqual(11, scale.len());
}

test "default mode generates a symmetric gradient" {
    var allocator = std.testing.allocator;
    const base = [3]u8{128, 64, 32};
    const scale_size: usize = 6;

    var scale = try color.ColorScale.init(&allocator, scale_size, base, color.Mode.Default);
    defer scale.free();

    const map = scale.map.?;

    const mid = scale_size / 2;

    try std.testing.expect(map[0][0] > map[mid][0]);
    try std.testing.expect(map[0][1] > map[mid][1]);
    try std.testing.expect(map[0][2] > map[mid][2]);

    try std.testing.expect(map[scale_size][0] < map[mid][0]);
    try std.testing.expect(map[scale_size][1] < map[mid][1]);
    try std.testing.expect(map[scale_size][2] < map[mid][2]);
}

test "linear mode fades linearly towards black" {
    var allocator = std.testing.allocator;
    const base = [3]u8{200, 100, 50};
    const scale_size: usize = 5;

    var scale = try color.ColorScale.init(&allocator, scale_size, base, color.Mode.Linear);
    defer scale.free();

    const map = scale.map.?;

    try std.testing.expect(map[0][0] > map[1][0]);
    try std.testing.expect(map[1][0] > map[2][0]);
    try std.testing.expect(map[2][0] > map[3][0]);
    try std.testing.expect(map[3][0] > map[4][0]);
    try std.testing.expect(map[4][0] > map[5][0]);
}

test "circular mode rises then falls symmetrically" {
    var allocator = std.testing.allocator;
    const base = [3]u8{255, 128, 64};
    const scale_size: usize = 6;

    var scale = try color.ColorScale.init(&allocator, scale_size, base, color.Mode.Circular);
    defer scale.free();

    const map = scale.map.?;

    const left = map[1][0];
    const mid = map[scale_size / 2][0];
    const right = map[scale_size][0];

    try std.testing.expect(left < mid); 
    try std.testing.expect(mid > right);
}

test "find and findUnsafe work correctly" {
    var allocator = std.testing.allocator;
    const base = [3]u8{100, 100, 100};
    var scale = try color.ColorScale.init(&allocator, 3, base, color.Mode.Linear);
    defer scale.free();

    try std.testing.expect(scale.find(10) == null);
    try std.testing.expect(scale.findUnsafe(10) == null);
    try std.testing.expect(scale.find(1) != null);
}

test "free releases memory and resets map" {
    var allocator = std.testing.allocator;
    const base = [3]u8{255, 255, 255};
    var scale = try color.ColorScale.init(&allocator, 5, base, color.Mode.Default);

    scale.free();
    try std.testing.expectEqual(@as(usize, 0), scale.len());
}
