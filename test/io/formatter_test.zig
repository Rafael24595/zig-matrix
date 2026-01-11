const std = @import("std");

const formatter = @import("root.zig").formatter;

test "Formatter with u8 adapter (ANSI 256)" {
    var f = formatter.AnsiFormatter{};

    const allocator = std.testing.allocator;

    const buf = try allocator.alloc(u8, f.fmt_bytes());
    defer allocator.free(buf);

    const out = try f.format(buf, 255, 0, 0, 'X');

    try std.testing.expectEqualStrings(
        "\x1b[38;5;196mX",
        out,
    );
}

test "Formatter with Rgb adapter (RGB)" {
    var f = formatter.RgbFormatter{};

    const allocator = std.testing.allocator;

    const buf = try allocator.alloc(u8, f.fmt_bytes());
    defer allocator.free(buf);

    const out = try f.format(buf, 255, 0, 144, 'X');

    try std.testing.expectEqualStrings(
        "\x1b[38;2;255;0;144mX",
        out,
    );
}

test "FormatterUnion with ANSI and RGB adapter" {
    var f = formatter.FormatterUnion{ .rgb = .{} };

    const allocator = std.testing.allocator;

    var buf = try allocator.alloc(u8, f.fmt_bytes());

    var out = try f.format(buf, 255, 0, 144, 'X');
    try std.testing.expectEqualStrings(
        "\x1b[38;2;255;0;144mX",
        out,
    );

    allocator.free(buf);

    buf = try allocator.alloc(u8, f.fmt_bytes());

    f = formatter.FormatterUnion{ .ansi = .{} };
    out = try f.format(buf, 255, 0, 0, 'X');
    try std.testing.expectEqualStrings(
        "\x1b[38;5;196mX",
        out,
    );

    allocator.free(buf);
}
