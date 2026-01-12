const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

pub const Mode = enum {
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

const ASCII_TABLE = Table{
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

const BINARY_TABLE = Table{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "0", "1",
    },
};

const LATIN_TABLE = mixTables(&LATIN_UPPER_TABLE, &LATIN_LOWER_TABLE);

const LATIN_UPPER_TABLE = Table{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    },
};

const LATIN_LOWER_TABLE = Table{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    },
};

const DIGITS_TABLE = Table{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    },
};

const SYMBOLS_TABLE = Table{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "=",  "+",
        "[", "]", "{", "}", ";", ":", ",", ".", "<", ">", "?", "/", "\\", "|",
        "~",
    },
};

const HEX_TABLE = Table{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "A", "B", "C", "D", "E", "F",
    },
};

const BASE64_TABLE = Table{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
        "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f",
        "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
        "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/",
    },
};

const BLOCKS_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "█", "▓", "▒", "░",
        "─", "━", "│", "┃",
        "┌", "┐", "└", "┘",
        "├", "┤", "┬", "┴",
        "┼",
    },
};

const EXTENDED_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "§",  "¶",  "±",  "µ",  "¤",
        "©",  "®",  "™", "°",  "•",
        "∞", "≠", "≈", "≤", "≥",
    },
};

const KATAKANA_TABLE = Table{
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

const FADE_TABLE = Table{
    .max_bytes = 1,
    .chars = &[_][]const u8{
        " ", ".", ":", "-", "=", "+", "*", "#", "%", "@",
    },
};

const MATRIX_RAIN_TABLE = mixTables(&KATAKANA_TABLE, &DIGITS_TABLE);

const CODE_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "0", "1", "{", "}", "[", "]",
        "<", ">", "=", ";", "_",
    },
};

const SCIFI_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "·",  "•", "°",  "*",   "+", "×",
        "≡", "⊕", "⊗", "∆",
    },
};

const RUNES_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᚲ", "ᚷ", "ᚹ", "ᚺ",
        "ᛁ", "ᛃ", "ᛇ", "ᛈ", "ᛉ", "ᛋ", "ᛏ", "ᛒ", "ᛖ",
    },
};

const MATH_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "±",  "×",  "÷",  "=",   "≠",
        "<",   ">",   "≤", "≥", "≈",
        "≡", "∑", "∏", "√", "∞",
        "∂", "∆",
    },
};

const ARCANE_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "⊗", "⊕", "⊖", "⊘",
        "∆", "∇", "∴", "∵",
        "⌘", "⌬", "⌗",
    },
};

const TELEMETRY_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "◁", "▷", "△", "▽",
        "◯", "◎", "◉", "+",
        "×",  "−", "≡", "≈",
    },
};

const CYRILLIC_TABLE = mixTables(&CYRILLIC_UPPER_TABLE, &CYRILLIC_LOWER_TABLE);

const CYRILLIC_UPPER_TABLE = Table{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М",
        "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ",
        "Ы", "Ь", "Э", "Ю", "Я",
    },
};

const CYRILLIC_LOWER_TABLE = Table{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м",
        "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ",
        "ы", "ь", "э", "ю", "я",
    },
};

const GREEK_TABLE = mixTables(&GREEK_UPPER_TABLE, &GREEK_LOWER_TABLE);

const GREEK_UPPER_TABLE = Table{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "Α", "Β", "Γ", "Δ", "Ε", "Ζ", "Η", "Θ", "Ι", "Κ", "Λ", "Μ",
        "Ν", "Ξ", "Ο", "Π", "Ρ", "Σ", "Τ", "Υ", "Φ", "Χ", "Ψ", "Ω",
    },
};

const GREEK_LOWER_TABLE = Table{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ",
        "ν", "ξ", "ο", "π", "ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω",
    },
};

const ARABIC_TABLE = Table{
    .max_bytes = 2,
    .chars = &[_][]const u8{
        "ء", "آ", "أ", "ؤ", "إ", "ئ", "ا", "ب", "ة", "ت", "ث", "ج", "ح", "خ", "د", "ذ",
        "ر", "ز", "س", "ش", "ص", "ض", "ط", "ظ", "ع", "غ", "ف", "ق", "ك", "ل", "م", "ن",
        "ه", "و", "ي",
    },
};

const DEVANAGARI_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "अ", "आ", "इ", "ई", "उ", "ऊ", "ऋ", "ऌ", "ए", "ऐ", "ओ", "औ",
        "क", "ख", "ग", "घ", "ङ", "च", "छ", "ज", "झ", "ञ", "ट", "ठ",
        "ड", "ढ", "ण", "त", "थ", "द", "ध", "न", "प", "फ", "ब", "भ",
        "म", "य", "र", "ल", "व", "श", "ष", "स", "ह",
    },
};

const CHINESE_TABLE = Table{
    .max_bytes = 3,
    .chars = &[_][]const u8{
        "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
        "口", "日", "月", "山", "水", "火", "木", "金", "土", "田",
        "人", "口", "子", "女", "心", "手", "目", "耳", "足", "心",
        "天", "生", "学", "力", "気", "心", "王", "中", "大", "小",
        "上", "下", "左", "右", "文", "字", "語", "書", "行", "食",
    },
};

const EMOJI_TABLE = Table{
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

fn mixTables(a: *const Table, b: *const Table) Table {
    return Table{
        .max_bytes = @max(a.max_bytes, b.max_bytes),
        .chars = a.chars ++ b.chars,
    };
}

const Table = struct {
    max_bytes: usize,
    chars: []const []const u8,
};

pub const AsciiGenerator = struct {
    lcg: *MiniLCG,

    table: Table,

    pub fn init(lcg: *MiniLCG, mode: Mode) @This() {
        return AsciiGenerator{
            .lcg = lcg,
            .table = range(mode),
        };
    }

    fn range(mode: Mode) Table {
        return switch (mode) {
            Mode.Default => ASCII_TABLE,
            Mode.Binary => BINARY_TABLE,
            Mode.Latin => LATIN_TABLE,
            Mode.LatinUpper => LATIN_UPPER_TABLE,
            Mode.LatinLower => LATIN_LOWER_TABLE,
            Mode.Digits => DIGITS_TABLE,
            Mode.Symbols => SYMBOLS_TABLE,
            Mode.Hex => HEX_TABLE,
            Mode.Base64 => BASE64_TABLE,
            Mode.Blocks => BLOCKS_TABLE,
            Mode.Extended => EXTENDED_TABLE,
            Mode.Katana => KATAKANA_TABLE,
            Mode.Fade => FADE_TABLE,
            Mode.Matrix => MATRIX_RAIN_TABLE,
            Mode.Code => CODE_TABLE,
            Mode.SciFi => SCIFI_TABLE,
            Mode.Runes => RUNES_TABLE,
            Mode.Math => MATH_TABLE,
            Mode.Arcane => ARCANE_TABLE,
            Mode.Telemetry => TELEMETRY_TABLE,
            Mode.Cyrilic => CYRILLIC_TABLE,
            Mode.CyrilicUpper => CYRILLIC_UPPER_TABLE,
            Mode.CyrilicLower => CYRILLIC_LOWER_TABLE,
            Mode.Greek => GREEK_TABLE,
            Mode.GreekUpper => GREEK_UPPER_TABLE,
            Mode.GreekLower => GREEK_LOWER_TABLE,
            Mode.Arabic => ARABIC_TABLE,
            Mode.Devanagari => DEVANAGARI_TABLE,
            //Mode.Chinese => CHINESE_TABLE,
            //Mode.Emoji => EMOJI_TABLE,
        };
    }

    pub fn max_bytes(self: *@This()) usize {
        return self.table.max_bytes;
    }

    pub fn next(self: *@This()) []const u8 {
        const chars = self.table.chars;
        const idx = self.lcg.randInRange(0, @intCast(chars.len - 1));
        return chars[idx];
    }
};
