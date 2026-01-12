const std = @import("std");

const MiniLCG = @import("root.zig").MiniLCG;
const ascii = @import("root.zig").ascii;

test "next uses table for Symbols mode" {
    var lcg = MiniLCG.init(1234);
    var gen = ascii.AsciiGenerator.init(&lcg, ascii.Mode.Symbols);
    const tbl = gen.table.chars;

    for (0..100) |_| {
        const ch = gen.next();
        var found = false;
        for (tbl) |tch| {
            if (std.mem.eql(u8, ch, tch)) {
                found = true;
                break;
            }
        }
        try std.testing.expect(found);
    }
}
