const std = @import("std");

pub const FormatterCode = enum {
    ANSI,
    RGB,
    VOID,
};

pub fn unionOf(f: FormatterCode) FormatterUnion {
    return switch (f) {
        FormatterCode.ANSI => FormatterUnion{ .ansi = .{} },
        FormatterCode.RGB => FormatterUnion{ .rgb = .{} },
        FormatterCode.VOID => FormatterUnion{ .void = .{} },
    };
}

pub const FormatterUnion = union(enum) {
    ansi: AnsiFormatter,
    rgb: RgbFormatter,
    void: VoidFormatter,

    pub fn code(
        self: @This(),
    ) FormatterCode {
        return switch (self) {
            .ansi => |f| f.code(),
            .rgb => |f| f.code(),
            .void => |f| f.code(),
        };
    }

    pub fn fmt_bytes(
        self: *@This(),
    ) usize {
        return switch (self.*) {
            .ansi => |f| f.fmt_bytes(),
            .rgb => |f| f.fmt_bytes(),
            .void => |f| f.fmt_bytes(),
        };
    }

    pub fn prefix(
        self: *@This(),
    ) []const u8 {
        return switch (self.*) {
            .ansi => |f| f.prefix(),
            .rgb => |f| f.prefix(),
            .void => |f| f.prefix(),
        };
    }

    pub fn sufix(
        self: *@This(),
    ) []const u8 {
        return switch (self.*) {
            .ansi => |f| f.sufix(),
            .rgb => |f| f.sufix(),
            .void => |f| f.sufix(),
        };
    }

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
    FormatterCode.ANSI,
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

        const gray_index: u8 = @intCast(((r - 8) * 24) / 247);
        return .{ 232 + gray_index, c };
    }

    const rr = (@as(u16, r) * 5) / 255;
    const gg = (@as(u16, g) * 5) / 255;
    const bb = (@as(u16, b) * 5) / 255;

    return .{ @intCast(16 + 36 * rr + 6 * gg + bb), c };
}

pub const RgbFormatter = Formatter(
    FormatterCode.RGB,
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
    FormatterCode.VOID,
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
