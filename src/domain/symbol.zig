const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

pub const Theme = enum {
    Default,
    Binary,
    Latin,
    LatinUpper,
    LatinLower,
    Digits,
    Symbols,
    Hex,
    Base64,
    Blocks,
    Extended,
    Katana,
    Fade,
    Matrix,
    Code,
    SciFi,
    Runes,
    Math,
    Arcane,
    Telemetry,
    Cyrilic,
    CyrilicUpper,
    CyrilicLower,
    Greek,
    GreekUpper,
    GreekLower,
    Arabic,
    Devanagari,
    //Chinese,
    //Emoji
};

const ThemeMeta = struct {
    max_bytes: usize,
    chars: []const []const u8,
};

fn mixTables(a: *const ThemeMeta, b: *const ThemeMeta) ThemeMeta {
    return ThemeMeta{
        .max_bytes = @max(a.max_bytes, b.max_bytes),
        .chars = a.chars ++ b.chars,
    };
}

const ThemeMap = [_]ThemeMeta{
    ASCII_TABLE,
    BINARY_TABLE,
    LATIN_TABLE,
    LATIN_UPPER_TABLE,
    LATIN_LOWER_TABLE,
    DIGITS_TABLE,
    SYMBOLS_TABLE,
    HEX_TABLE,
    BASE64_TABLE,
    BLOCKS_TABLE,
    EXTENDED_TABLE,
    KATAKANA_TABLE,
    FADE_TABLE,
    MATRIX_RAIN_TABLE,
    CODE_TABLE,
    SCIFI_TABLE,
    RUNES_TABLE,
    MATH_TABLE,
    ARCANE_TABLE,
    TELEMETRY_TABLE,
    CYRILLIC_TABLE,
    CYRILLIC_UPPER_TABLE,
    CYRILLIC_LOWER_TABLE,
    GREEK_TABLE,
    GREEK_UPPER_TABLE,
    GREEK_LOWER_TABLE,
    ARABIC_TABLE,
    DEVANAGARI_TABLE,
};

const ASCII_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/",
        "0", "1",  "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">",
        "?", "@",  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O",  "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\",
        "]", "^",  "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
        "l", "m",  "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "{", "|",  "}", "~",
    },
};

const BINARY_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "0", "1",
    },
};

const LATIN_TABLE = mixTables(&LATIN_UPPER_TABLE, &LATIN_LOWER_TABLE);

const LATIN_UPPER_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    },
};

const LATIN_LOWER_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    },
};

const DIGITS_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    },
};

const SYMBOLS_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "=",  "+",
        "[", "]", "{", "}", ";", ":", ",", ".", "<", ">", "?", "/", "\\", "|",
        "~",
    },
};

const HEX_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "A", "B", "C", "D", "E", "F",
    },
};

const BASE64_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
        "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f",
        "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
        "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/",
    },
};

const BLOCKS_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "█", "▓", "▒", "░",
        "─", "━", "│", "┃",
        "┌", "┐", "└", "┘",
        "├", "┤", "┬", "┴",
        "┼",
    },
};

const EXTENDED_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "§",  "¶",  "±",  "µ",  "¤",
        "©",  "®",  "™", "°",  "•",
        "∞", "≠", "≈", "≤", "≥",
    },
};

const KATAKANA_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "ｦ", "ｧ", "ｨ", "ｩ", "ｪ", "ｫ",
        "ｬ", "ｭ", "ｮ", "ｯ", "ｱ", "ｲ",
        "ｳ", "ｴ", "ｵ", "ｶ", "ｷ", "ｸ",
        "ｹ", "ｺ", "ｻ", "ｼ", "ｽ", "ｾ",
        "ｿ", "ﾀ", "ﾁ", "ﾂ", "ﾃ", "ﾄ",
        "ﾅ", "ﾆ", "ﾇ", "ﾈ", "ﾉ", "ﾊ",
        "ﾋ", "ﾌ", "ﾍ", "ﾎ", "ﾏ", "ﾐ",
        "ﾑ", "ﾒ", "ﾓ", "ﾔ", "ﾕ", "ﾖ",
        "ﾗ", "ﾘ", "ﾙ", "ﾚ", "ﾛ", "ﾜ",
        "ﾝ",
    },
};

const FADE_TABLE = ThemeMeta{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        " ", ".", ":", "-", "=", "+", "*", "#", "%", "@",
    },
};

const MATRIX_RAIN_TABLE = mixTables(&KATAKANA_TABLE, &DIGITS_TABLE);

const CODE_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "0", "1", "{", "}", "[", "]",
        "<", ">", "=", ";", "_",
    },
};

const SCIFI_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "·",  "•", "°",  "*",   "+", "×",
        "≡", "⊕", "⊗", "∆",
    },
};

const RUNES_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᚲ", "ᚷ", "ᚹ", "ᚺ",
        "ᛁ", "ᛃ", "ᛇ", "ᛈ", "ᛉ", "ᛋ", "ᛏ", "ᛒ", "ᛖ",
    },
};

const MATH_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "±",  "×",  "÷",  "=",   "≠",
        "<",   ">",   "≤", "≥", "≈",
        "≡", "∑", "∏", "√", "∞",
        "∂", "∆",
    },
};

const ARCANE_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "⊗", "⊕", "⊖", "⊘",
        "∆", "∇", "∴", "∵",
        "⌘", "⌬", "⌗",
    },
};

const TELEMETRY_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "◁", "▷", "△", "▽",
        "◯", "◎", "◉", "+",
        "×",  "−", "≡", "≈",
    },
};

const CYRILLIC_TABLE = mixTables(&CYRILLIC_UPPER_TABLE, &CYRILLIC_LOWER_TABLE);

const CYRILLIC_UPPER_TABLE = ThemeMeta{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М",
        "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ",
        "Ы", "Ь", "Э", "Ю", "Я",
    },
};

const CYRILLIC_LOWER_TABLE = ThemeMeta{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м",
        "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ",
        "ы", "ь", "э", "ю", "я",
    },
};

const GREEK_TABLE = mixTables(&GREEK_UPPER_TABLE, &GREEK_LOWER_TABLE);

const GREEK_UPPER_TABLE = ThemeMeta{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "Α", "Β", "Γ", "Δ", "Ε", "Ζ", "Η", "Θ", "Ι", "Κ", "Λ", "Μ",
        "Ν", "Ξ", "Ο", "Π", "Ρ", "Σ", "Τ", "Υ", "Φ", "Χ", "Ψ", "Ω",
    },
};

const GREEK_LOWER_TABLE = ThemeMeta{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ",
        "ν", "ξ", "ο", "π", "ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω",
    },
};

const ARABIC_TABLE = ThemeMeta{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "ء", "آ", "أ", "ؤ", "إ", "ئ", "ا", "ب", "ة", "ت", "ث", "ج", "ح", "خ", "د", "ذ",
        "ر", "ز", "س", "ش", "ص", "ض", "ط", "ظ", "ع", "غ", "ف", "ق", "ك", "ل", "م", "ن",
        "ه", "و", "ي",
    },
};

const DEVANAGARI_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "अ", "आ", "इ", "ई", "उ", "ऊ", "ऋ", "ऌ", "ए", "ऐ", "ओ", "औ",
        "क", "ख", "ग", "घ", "ङ", "च", "छ", "ज", "झ", "ञ", "ट", "ठ",
        "ड", "ढ", "ण", "त", "थ", "द", "ध", "न", "प", "फ", "ब", "भ",
        "म", "य", "र", "ल", "व", "श", "ष", "स", "ह",
    },
};

const CHINESE_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
        "口", "日", "月", "山", "水", "火", "木", "金", "土", "田",
        "人", "口", "子", "女", "心", "手", "目", "耳", "足", "心",
        "天", "生", "学", "力", "気", "心", "王", "中", "大", "小",
        "上", "下", "左", "右", "文", "字", "語", "書", "行", "食",
    },
};

const EMOJI_TABLE = ThemeMeta{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "↑", "↓", "→", "←", "↖", "↗", "↘", "↙", "⇑", "⇓", "⇐", "⇒",
        "★", "☆", "☀", "☁", "☂", "☃", "☄", "☾", "☽", "■", "□", "◆",
        "◇", "▲", "△", "▼", "▽", "●", "○", "▤", "▥", "▦", "▧", "▨",
        "▩", "✈", "✉", "☎", "✂", "✏", "✒", "✿", "✾", "❀", "❁", "❂",
        "❃", "❄", "❅", "❆", "❇", "±",  "×",  "÷",  "=",   "≠", "≤", "≥",
        "≈", "∞", "∂", "∇", "∑", "∏",
    },
};

pub fn metaOf(m: Theme) ThemeMeta {
    return ThemeMap[@intFromEnum(m)];
}

pub const SymbolGenerator = struct {
    lcg: *MiniLCG,

    meta: ThemeMeta,

    pub fn init(lcg: *MiniLCG, mode: Theme) @This() {
        return SymbolGenerator{
            .lcg = lcg,
            .meta = metaOf(mode),
        };
    }

    pub fn max_bytes(self: *@This()) usize {
        return self.meta.max_bytes;
    }

    pub fn next(self: *@This()) []const u8 {
        const chars = self.meta.chars;
        const idx = self.lcg.randInRange(0, @intCast(chars.len - 1));
        return chars[idx];
    }
};
