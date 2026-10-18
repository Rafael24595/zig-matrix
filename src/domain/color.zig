const std = @import("std");

const kit_color = @import("terminal_kit").color;

/// Selects the gradient algorithm used to generate a color scale.
pub const ThemeGradient = enum {
    default,
    linear,
    circular,
};

/// Stores a dynamically allocated sequence of RGB colors generated
/// from a base color and a gradient mode.
pub const ColorScale = struct {
    /// Allocator used to allocate the color map.
    allocator: std.mem.Allocator,
    /// Generated RGB entries, or null when no map is allocated.
    map: ?[][3]u8 = null,

    /// Algorithm used to generate the color map.
    mode: ThemeGradient = ThemeGradient.default,

    /// Allocates and generates a color map containing `scale + 1` entries.
    ///
    /// `base` supplies the RGB color used by the selected gradient.
    /// The caller must release the allocated map with `free`.
    pub fn init(
        allocator: std.mem.Allocator,
        scale: usize,
        base: [3]u8,
        mode: ThemeGradient,
    ) !@This() {
        var self = ColorScale{ .allocator = allocator, .mode = mode };

        self.map = try self.allocator.alloc([3]u8, scale + 1);

        const map = self.map.?;
        for (0..scale + 1) |i| {
            switch (mode) {
                ThemeGradient.default => {
                    map[i] = scale_color_default(i, scale, base);
                },
                ThemeGradient.circular => {
                    map[i] = scale_color_circular(i, scale, base);
                },
                ThemeGradient.linear => {
                    map[i] = scale_color_linear(i, scale, base);
                },
            }
        }

        return self;
    }

    /// Returns the RGB value at `index`, or null if the map is unallocated
    /// or the index is out of bounds.
    pub inline fn find(self: @This(), index: usize) ?[3]u8 {
        if (self.map == null) {
            return null;
        }

        return self.find_unsafe(index);
    }

    /// Returns the RGB value at `index`, or null if it is out of bounds.
    ///
    /// Requires the map to be allocated; unlike `find`, this method
    /// does not check whether the map is null.
    pub inline fn find_unsafe(self: @This(), index: usize) ?[3]u8 {
        if (index >= self.map.?.len) {
            return null;
        }

        return self.map.?[index];
    }

    /// Returns the number of allocated color entries, or zero if no map exists.
    pub fn len(self: *@This()) usize {
        if (self.map == null) {
            return 0;
        }

        return self.map.?.len;
    }

    /// Releases the color map and resets `map` to null.
    /// Safe to call when the map is already null.
    pub fn free(self: *@This()) void {
        if (self.map) |m| {
            self.allocator.free(m);
            self.map = null;
        }
    }

    inline fn scale_color_circular(index: usize, max: usize, mid: [3]u8) [3]u8 {
        if (max < 2) {
            return .{ 255, 255, 255 };
        }

        const fi: f32 = @floatFromInt(index);
        const fm: f32 = @floatFromInt(max);

        var per: f32 = 0;
        if (index < max / 2) {
            per = fi / fm;
        } else {
            per = 1 - (fi / fm);
        }

        const r: f32 = @floatFromInt(mid[0]);
        const g: f32 = @floatFromInt(mid[1]);
        const b: f32 = @floatFromInt(mid[2]);

        return .{
            clamp(r * per),
            clamp(g * per),
            clamp(b * per),
        };
    }

    inline fn scale_color_linear(index: usize, max: usize, mid: [3]u8) [3]u8 {
        if (max < 2) {
            return .{ 255, 255, 255 };
        }

        const fi: f32 = @floatFromInt(index);
        const fm: f32 = @floatFromInt(max);
        const per: f32 = 1 - (fi / fm);

        const r: f32 = @floatFromInt(mid[0]);
        const g: f32 = @floatFromInt(mid[1]);
        const b: f32 = @floatFromInt(mid[2]);

        return .{
            clamp(r * per),
            clamp(g * per),
            clamp(b * per),
        };
    }

    inline fn scale_color_default(index: usize, max: usize, mid: [3]u8) [3]u8 {
        if (max < 2) {
            return .{ 255, 255, 255 };
        }

        const half = max / 2;

        if (index <= half) {
            return upper_color(index, half, mid);
        }

        return lower_color(index - half, max - half, mid);
    }

    inline fn lower_color(index: usize, max: usize, mid: [3]u8) [3]u8 {
        const fi: f32 = @floatFromInt(index);
        const fh: f32 = @floatFromInt(max);
        const t = fi / fh;

        const r = lerp(@floatFromInt(mid[0]), 0.0, t);
        const g = lerp(@floatFromInt(mid[1]), 0.0, t);
        const b = lerp(@floatFromInt(mid[2]), 0.0, t);

        return .{
            clamp(r),
            clamp(g),
            clamp(b),
        };
    }

    inline fn upper_color(index: usize, half: usize, mid: [3]u8) [3]u8 {
        const fi: f32 = @floatFromInt(index);
        const fh: f32 = @floatFromInt(half);
        const t = fi / fh;

        const r = lerp(255.0, @floatFromInt(mid[0]), t);
        const g = lerp(255.0, @floatFromInt(mid[1]), t);
        const b = lerp(255.0, @floatFromInt(mid[2]), t);

        return .{
            clamp(r),
            clamp(g),
            clamp(b),
        };
    }

    inline fn clamp(color: f32) u8 {
        return @intFromFloat(@round(std.math.clamp(color, 0.0, 255.0)));
    }

    inline fn lerp(a: f32, b: f32, t: f32) f32 {
        return a + (b - a) * t;
    }
};

test "correct RGB values for known colors" {
    try std.testing.expectEqual([3]u8{ 255, 0, 0 }, kit_color.rgb_of(kit_color.Color.red));
    try std.testing.expectEqual([3]u8{ 0, 255, 0 }, kit_color.rgb_of(kit_color.Color.green));
    try std.testing.expectEqual([3]u8{ 0, 0, 255 }, kit_color.rgb_of(kit_color.Color.blue));
}

test "init creates map with correct length" {
    const allocator = std.testing.allocator;
    
    const base = [3]u8{ 128, 128, 128 };
    var scale = try ColorScale.init(allocator, 10, base, ThemeGradient.linear);
    defer scale.free();

    try std.testing.expectEqual(11, scale.len());
}

test "default mode generates a symmetric gradient" {
    const allocator = std.testing.allocator;

    const base = [3]u8{ 128, 64, 32 };
    const scale_size: usize = 6;

    var scale = try ColorScale.init(allocator, scale_size, base, ThemeGradient.default);
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
    const allocator = std.testing.allocator;

    const base = [3]u8{ 200, 100, 50 };
    const scale_size: usize = 5;

    var scale = try ColorScale.init(allocator, scale_size, base, ThemeGradient.linear);
    defer scale.free();

    const map = scale.map.?;

    try std.testing.expect(map[0][0] > map[1][0]);
    try std.testing.expect(map[1][0] > map[2][0]);
    try std.testing.expect(map[2][0] > map[3][0]);
    try std.testing.expect(map[3][0] > map[4][0]);
    try std.testing.expect(map[4][0] > map[5][0]);
}

test "circular mode rises then falls symmetrically" {
    const allocator = std.testing.allocator;

    const base = [3]u8{ 255, 128, 64 };
    const scale_size: usize = 6;

    var scale = try ColorScale.init(allocator, scale_size, base, ThemeGradient.circular);
    defer scale.free();

    const map = scale.map.?;

    const left = map[1][0];
    const mid = map[scale_size / 2][0];
    const right = map[scale_size][0];

    try std.testing.expect(left < mid);
    try std.testing.expect(mid > right);
}

test "find and findUnsafe work correctly" {
    const allocator = std.testing.allocator;

    const base = [3]u8{ 100, 100, 100 };
    var scale = try ColorScale.init(allocator, 3, base, ThemeGradient.linear);
    defer scale.free();

    try std.testing.expect(scale.find(10) == null);
    try std.testing.expect(scale.find_unsafe(10) == null);
    try std.testing.expect(scale.find(1) != null);
}

test "free releases memory and resets map" {
    const allocator = std.testing.allocator;

    const base = [3]u8{ 255, 255, 255 };
    var scale = try ColorScale.init(allocator, 5, base, ThemeGradient.default);

    scale.free();
    try std.testing.expectEqual(@as(usize, 0), scale.len());
}
