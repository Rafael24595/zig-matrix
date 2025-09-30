pub const MiniLCG = struct {
    seed: u32 = 1,

    fn next(self: *MiniLCG) u32 {
        const mul = @mulWithOverflow(self.seed, 1664525);
        const add = @addWithOverflow(mul[0], 1013904223);
        self.seed = add[0];
        return self.seed;
    }

    pub fn randInRange(self: *MiniLCG, min: u8, max: u8) u8 {
        var rnd: u32 = self.next();

        rnd = ((rnd >> 16) ^ (rnd >> 8)) & 0xFFFF;

        const min32: u32 = @intCast(min);
        const max32: u32 = @intCast(max);

        const range: u32 = max32 - min32 + 1;
        const value: u32 = rnd % range;

        return @intCast(min32 + value);
    }
};
