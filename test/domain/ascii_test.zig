const std = @import("std");

const MiniLCG = @import("root.zig").MiniLCG;
const ascii = @import("root.zig").ascii;

test "returns values within ASCII range" {
    var lcg = MiniLCG.init(1234);
    var gen = ascii.AsciiGenerator.init(&lcg, ascii.Mode.Uppercase);

    const start = gen.ascii_start;
    const end = gen.ascii_end;

    for (0..100) |_| {
        const ch = gen.next();
        try std.testing.expect(ch >= start and ch <= end);
    }
}

test "next uses table for Symbols mode" {
    var lcg = MiniLCG.init(1234);
    var gen = ascii.AsciiGenerator.init(&lcg, ascii.Mode.Symbols);
    const tbl = gen.table.?;

    for (0..100) |_| {
        const ch = gen.next();
        var found = false;
        for (tbl) |tch| {
            if (ch == tch) {
                found = true;
                break;
            }
        }
        try std.testing.expect(found);
    }
}