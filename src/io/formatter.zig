const std = @import("std");

/// Selects the color formatting strategy used for terminal output.
pub const FormatterCode = enum {
    /// Uses the 256-color ANSI palette.
    ansi,
    /// Uses 24-bit RGB ANSI escape sequences.
    rgb,
    /// Outputs the character without a foreground color sequence.
    none,
};

/// Creates a formatter for the selected output format.
pub fn union_of(f: FormatterCode) FormatterUnion {
    return switch (f) {
        FormatterCode.ansi => FormatterUnion{ .ansi = .{} },
        FormatterCode.rgb => FormatterUnion{ .rgb = .{} },
        FormatterCode.none => FormatterUnion{ .void = .{} },
    };
}

/// Type-erased interface for the supported terminal formatters.
pub const FormatterUnion = union(enum) {
    ansi: AnsiFormatter,
    rgb: RgbFormatter,
    void: VoidFormatter,

    /// Returns the format code identifying the active formatter.
    pub fn code(self: @This()) FormatterCode {
        return switch (self) {
            .ansi => |f| f.code(),
            .rgb => |f| f.code(),
            .void => |f| f.code(),
        };
    }

    /// Returns the buffer capacity recommended for formatting one character.
    pub fn fmt_bytes(self: @This()) usize {
        return switch (self) {
            .ansi => |f| f.fmt_bytes(),
            .rgb => |f| f.fmt_bytes(),
            .void => |f| f.fmt_bytes(),
        };
    }

    /// Returns the prefix emitted before the formatted character.
    pub fn prefix(self: @This()) []const u8 {
        return switch (self) {
            .ansi => |f| f.prefix(),
            .rgb => |f| f.prefix(),
            .void => |f| f.prefix(),
        };
    }

    /// Returns the suffix emitted after the formatted character.
    pub fn sufix(self: @This()) []const u8 {
        return switch (self) {
            .ansi => |f| f.sufix(),
            .rgb => |f| f.sufix(),
            .void => |f| f.sufix(),
        };
    }

    /// Formats a character using the selected color strategy.
    ///
    /// The returned slice refers to `buffer`, which must have sufficient
    /// capacity and remain valid while the result is used.
    pub fn format(
        self: @This(),
        buffer: []u8,
        r: u8,
        g: u8,
        b: u8,
        c: []const u8,
    ) ![]const u8 {
        return switch (self) {
            .ansi => |f| f.format(buffer, r, g, b, c),
            .rgb => |f| f.format(buffer, r, g, b, c),
            .void => |f| f.format(buffer, r, g, b, c),
        };
    }
};

fn Formatter(
    comptime adapter_code: FormatterCode,
    comptime AdapterReturn: type,
    comptime char_fmt_bytes: usize,
    comptime prefix_fmt: []const u8,
    comptime sufix_fmt: []const u8,
    comptime char_fmt: []const u8,
    comptime adapter: fn (r: u8, g: u8, b: u8, c: []const u8) AdapterReturn,
) type {
    return struct {
        pub fn code(_: @This()) FormatterCode {
            return adapter_code;
        }

        pub fn fmt_bytes(_: @This()) usize {
            return char_fmt_bytes;
        }

        pub fn prefix(_: @This()) []const u8 {
            return prefix_fmt;
        }

        pub fn sufix(_: @This()) []const u8 {
            return sufix_fmt;
        }

        pub fn format(
            _: @This(),
            buffer: []u8,
            r: u8,
            g: u8,
            b: u8,
            c: []const u8,
        ) ![]const u8 {
            return try std.fmt.bufPrint(
                buffer,
                char_fmt,
                adapter(r, g, b, c),
            );
        }
    };
}

pub const AnsiFormatter = Formatter(
    FormatterCode.ansi,
    struct { u8, []const u8 },
    24,
    "",
    "\x1b[0m",
    "\x1b[38;5;{d}m{s}",
    rgbToAnsi256,
);

fn rgbToAnsi256(r: u8, g: u8, b: u8, c: []const u8) struct { u8, []const u8 } {
    if (r == g and g == b) {
        if (r < 8) {
            return .{ 16, c };
        }
        if (r > 248) {
            return .{ 231, c };
        }

        const scaled_gray_offset = (@as(u16, r) - 8) * 24;
        const gray_index: u8 = @intCast(scaled_gray_offset / 247);

        return .{ 232 + gray_index, c };
    }

    const rr = (@as(u16, r) * 5) / 255;
    const gg = (@as(u16, g) * 5) / 255;
    const bb = (@as(u16, b) * 5) / 255;

    return .{ @intCast(16 + 36 * rr + 6 * gg + bb), c };
}

pub const RgbFormatter = Formatter(
    FormatterCode.rgb,
    struct { u8, u8, u8, []const u8 },
    32,
    "",
    "\x1b[0m",
    "\x1b[38;2;{d};{d};{d}m{s}",
    rgbVoid,
);

fn rgbVoid(r: u8, g: u8, b: u8, c: []const u8) struct { u8, u8, u8, []const u8 } {
    return .{ r, g, b, c };
}

pub const VoidFormatter = Formatter(
    FormatterCode.none,
    struct { []const u8 },
    1,
    "",
    "\x1b[0m",
    "{s}",
    unformatted,
);

fn unformatted(_: u8, _: u8, _: u8, c: []const u8) struct { []const u8 } {
    return .{c};
}

test "Formatter with u8 adapter (ANSI 256)" {
    var f = AnsiFormatter{};

    const allocator = std.testing.allocator;

    const buf = try allocator.alloc(u8, f.fmt_bytes());
    defer allocator.free(buf);

    const out = try f.format(buf, 255, 0, 0, "X");

    try std.testing.expectEqualStrings(
        "\x1b[38;5;196mX",
        out,
    );
}

test "Formatter with Rgb adapter (RGB)" {
    var f = RgbFormatter{};

    const allocator = std.testing.allocator;

    const buf = try allocator.alloc(u8, f.fmt_bytes());
    defer allocator.free(buf);

    const out = try f.format(buf, 255, 0, 144, "X");

    try std.testing.expectEqualStrings(
        "\x1b[38;2;255;0;144mX",
        out,
    );
}

test "FormatterUnion with ANSI and RGB adapter" {
    var f = FormatterUnion{ .rgb = .{} };

    const allocator = std.testing.allocator;

    var buf = try allocator.alloc(u8, f.fmt_bytes());

    var out = try f.format(buf, 255, 0, 144, "X");
    try std.testing.expectEqualStrings(
        "\x1b[38;2;255;0;144mX",
        out,
    );

    allocator.free(buf);

    buf = try allocator.alloc(u8, f.fmt_bytes());

    f = FormatterUnion{ .ansi = .{} };
    out = try f.format(buf, 255, 0, 0, "X");
    try std.testing.expectEqualStrings(
        "\x1b[38;5;196mX",
        out,
    );

    allocator.free(buf);
}

test "union_of selects the requested formatter" {
    try std.testing.expectEqual(
        FormatterCode.ansi,
        union_of(.ansi).code(),
    );
    try std.testing.expectEqual(
        FormatterCode.rgb,
        union_of(.rgb).code(),
    );
    try std.testing.expectEqual(
        FormatterCode.none,
        union_of(.none).code(),
    );
}

test "VoidFormatter returns the character without color formatting" {
    var f = VoidFormatter{};
    var buf: [8]u8 = undefined;

    const out = try f.format(&buf, 255, 128, 64, "X");

    try std.testing.expectEqualStrings("X", out);
}

test "FormatterUnion reports the active formatter properties" {
    const ansi = union_of(.ansi);
    const rgb = union_of(.rgb);
    const none = union_of(.none);

    try std.testing.expectEqual(FormatterCode.ansi, ansi.code());
    try std.testing.expectEqual(FormatterCode.rgb, rgb.code());
    try std.testing.expectEqual(FormatterCode.none, none.code());

    try std.testing.expectEqual(@as(usize, 24), ansi.fmt_bytes());
    try std.testing.expectEqual(@as(usize, 32), rgb.fmt_bytes());
    try std.testing.expectEqual(@as(usize, 1), none.fmt_bytes());
}
