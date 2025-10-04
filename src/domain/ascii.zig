const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

pub const Mode = enum {
    Default,
    Binary,
    Letters,
    Uppercase,
    Lowercase,
    Digits,
    Symbols,
    Hex,
    Base64,
//    Blocks,
//    Extended,
//    Katana,
    Fade
};

const LETTERS_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const SYMBOLS_TABLE = "!@#$%^&*()-_=+[]{};:,.<>?/\\|~";
const HEX_TABLE = "0123456789ABCDEF";
const BASE64_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
//const BLOCKS_TABLE = "█▓▒░─━│┃┌┐└┘├┤┬┴┼";
//const EXTENDED_TABLE = "§¶±µ¤©®™°•∞≠≈≤≥";
//const KATAKANA_TABLE = "ｦｧｨｩｪｫｬｭｮｯｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ";
const FADE_TABLE = " .:-=+*#%@";

const RangeOrTable = struct {
    start: u8,
    end: u8,
    table: ?[]const u8,
};

pub const AsciiGenerator = struct {
    lcg: *MiniLCG,

    ascii_start: u8 = 33,
    ascii_end: u8 = 126,

    table: ?[]const u8 = null,

    pub fn init(lcg: *MiniLCG, mode: Mode) AsciiGenerator {
        const rng = range(mode);
        return AsciiGenerator{
            .lcg = lcg,
            .ascii_start = rng.start,
            .ascii_end = rng.end,
            .table = rng.table,
        };
    }

    fn range(mode: Mode) RangeOrTable {
        return switch (mode) {
            Mode.Default => .{ .start = 33, .end = 126, .table = null },
            Mode.Binary => .{ .start = 48, .end = 49, .table = null },
            Mode.Letters => .{ .start = 0, .end = 0, .table = LETTERS_TABLE },
            Mode.Uppercase => .{ .start = 65, .end = 90, .table = null },
            Mode.Lowercase => .{ .start = 97, .end = 122, .table = null },
            Mode.Digits => .{ .start = 48, .end = 57, .table = null },
            Mode.Symbols => .{ .start = 0, .end = 0, .table = SYMBOLS_TABLE },
            Mode.Hex => .{ .start = 0, .end = 0, .table = HEX_TABLE },
            Mode.Base64 => .{ .start = 0, .end = 0, .table = BASE64_TABLE },
//            Mode.Blocks => .{ .start = 0, .end = 0, .table = BLOCKS_TABLE },
//            Mode.Extended => .{ .start = 0, .end = 0, .table = EXTENDED_TABLE },
//            Mode.Katana => .{ .start = 0, .end = 0, .table = KATAKANA_TABLE },
            Mode.Fade => .{ .start = 0, .end = 0, .table = FADE_TABLE },
        };
    }

    pub fn next(self: *AsciiGenerator) u8 {
        if (self.table) |tbl| {
            const idx = self.lcg.randInRange(0, @intCast(tbl.len - 1));
            return tbl[idx];
        } else {
            return self.lcg.randInRange(self.ascii_start, self.ascii_end);
        }
    }
};
