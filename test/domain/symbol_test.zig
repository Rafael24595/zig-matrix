const std = @import("std");

const MiniLCG = @import("root.zig").MiniLCG;
const symbol = @import("root.zig").symbol;

test "next uses table for Symbols mode" {
    var lcg = MiniLCG.init(1234);
    var gen = symbol.SymbolGenerator.init(&lcg, symbol.Theme.Symbols);
    const tbl = gen.meta.chars;

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
