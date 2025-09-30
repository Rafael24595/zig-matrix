const std = @import("std");

pub const Colors = struct {
    pub const White   = [3]u8{ 255, 255, 255 };
    pub const Black   = [3]u8{   0,   0,   0 };
    pub const Red     = [3]u8{ 255,   0,   0 };
    pub const Green   = [3]u8{   0, 255,   0 };
    pub const Blue    = [3]u8{   0,   0, 255 };
    pub const Yellow  = [3]u8{ 255, 255,   0 };
    pub const Cyan    = [3]u8{   0, 255, 255 };
    pub const Magenta = [3]u8{ 255,   0, 255 };
    pub const Orange  = [3]u8{ 255, 128,   0 };
    pub const Purple  = [3]u8{ 128,   0, 128 };
    pub const Gray    = [3]u8{ 128, 128, 128 };
};

pub const ColorScale = struct {
    allocator: *std.mem.Allocator,
    map: ?[][3]u8 = null,

    lineal: bool = false,

    pub fn initialize(self: *ColorScale, scale: usize, base: [3]u8) !void {
        if (self.map != null) {
            _ = self.free();
        }

        self.map = try self.allocator.alloc([3]u8, scale + 1);

        const map = self.map.?;
        for (0..scale + 1) |i| {
            if (self.lineal) {
                map[i] = self.scaleColorLinear(i, scale, base);
            } else {
                map[i] = self.scaleColorMiddle(i, scale, base);
            }
        }
    }

    pub fn find(self: *ColorScale, index: usize) ?[3]u8 {
        if (self.map == null) {
            return null;
        }

        if (index >= self.map.?.len) {
            return null;
        }

        return self.map.?[index];
    }

    pub fn len(self: *ColorScale) usize {
        if (self.map == null) {
            return 0;
        }

        return self.map.?.len;
    }

    pub fn free(self: *ColorScale) void {
        if (self.map) |m| {
            self.allocator.free(m);
            self.map = null;
        }
    }

    fn scaleColorLinear(_: *ColorScale, index: usize, max: usize, mid: [3]u8) [3]u8 {
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
            @intFromFloat(@round(r * per)),
            @intFromFloat(@round(g * per)),
            @intFromFloat(@round(b * per)),
        };
    }

    fn scaleColorMiddle(self: *ColorScale, index: usize, max: usize, mid: [3]u8) [3]u8 {
        if (max < 2) {
            return .{ 255, 255, 255 };
        }

        const half = max / 2;

        if (index <= half) {
            return self.upperColor(index, half, mid);
        }

        return self.lowerColor(index - half, max - half, mid);
    }

    fn lowerColor(_: *ColorScale, index: usize, max: usize, mid: [3]u8) [3]u8 {
        const fi: f32 = @floatFromInt(index);
        const fh: f32 = @floatFromInt(max);
        const t = fi / fh;

        const r = lerp(@floatFromInt(mid[0]), 0.0, t);
        const g = lerp(@floatFromInt(mid[1]), 0.0, t);
        const b = lerp(@floatFromInt(mid[2]), 0.0, t);

        return .{
            @intFromFloat(@round(r)),
            @intFromFloat(@round(g)),
            @intFromFloat(@round(b)),
        };
    }

    fn upperColor(_: *ColorScale, index: usize, half: usize, mid: [3]u8) [3]u8 {
        const fi: f32 = @floatFromInt(index);
        const fh: f32 = @floatFromInt(half);
        const t = fi / fh;

        const r = lerp(255.0, @floatFromInt(mid[0]), t);
        const g = lerp(255.0, @floatFromInt(mid[1]), t);
        const b = lerp(255.0, @floatFromInt(mid[2]), t);

        return .{
            @intFromFloat(@round(r)),
            @intFromFloat(@round(g)),
            @intFromFloat(@round(b)),
        };
    }

    fn lerp(a: f32, b: f32, t: f32) f32 {
        return a + (b - a) * t;
    }
};
