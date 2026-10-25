const kit_formatter = @import("terminal_kit").formatter;

/// Defines the supported terminal color formats.
pub const FormatterCode = enum {
    /// Uses the 256-color ANSI palette.
    ansi,
    /// Uses 24-bit RGB ANSI escape sequences.
    rgb,
    /// Outputs the character without a foreground color sequence.
    unfo,
};

pub fn matrix_union_of(_: FormatterCode) kit_formatter.FormatterMatrixUnion {
    return .{ .unfo = .{} };
}

pub fn cell_union_of(f: FormatterCode) kit_formatter.FormatterCellUnion {
    return switch (f) {
        FormatterCode.ansi => .{ .ansi = .{} },
        FormatterCode.rgb => .{ .rgb = .{} },
        FormatterCode.unfo => .{ .unfo = .{} },
    };
}
