const std = @import("std");

const build = @import("build.zig.zon");

const ascii = @import("../domain/ascii.zig");
const color = @import("../domain/color.zig");
const matrix = @import("../domain/matrix.zig");
const Printer = @import("../io/printer.zig").Printer;

pub const Configuration = struct {
    debug: bool = false,
    seed: u64 = 0,
    milliseconds: u64 = 50,
    dropLen: usize = 10,
    rainColor: color.Color = .Green,
    rainMode: color.Mode = .Default,
    asciiMode: ascii.Mode = .Default,
    matrixMode: matrix.Mode = .Rain,

    pub fn init(args: [][:0]u8, printer: *Printer) !Configuration {
        defer printer.reset();

        var config = Configuration{};

        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try printer.printf(
                    \\Usage: zig-matrix   [options]
                    \\  -h, --help        Show this help message
                    \\  -v, --version     Show project's version
                    \\  -d                Enable debug mode (default: off)
                    \\  -s  <number>      Random seed (default: actual date in ms)
                    \\  -ms <number>      Frame delay in ms (default: {d})
                    \\  -l  <number>      Drop length (default: {d})
                    \\  -c  <color>       Rain color (default: {s})
                    \\                      (use "help" to list available colors)
                    \\  -g  <mode>        Rain color gradient (default: {s})
                    \\                      (use "help" to list available modes)
                    \\  -r  <mode>        ASCII mode (default: {s})
                    \\                      (use "help" to list available modes)
                    \\  -m  <mode>        Matrix mode (default: {s})
                    \\                      (use "help" to list available modes)
                , .{ config.milliseconds, config.dropLen, @tagName(config.rainColor), @tagName(config.rainMode), @tagName(config.asciiMode), @tagName(config.matrixMode) });
                std.process.exit(0);
            } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
                try printer.printf("{any}: {s}\n", .{ build.name, build.version });
                std.process.exit(0);
            } else if (std.mem.eql(u8, arg, "-d")) {
                config.debug = true;
            } else if (std.mem.eql(u8, arg, "-s")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -s (seed)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                config.seed = std.fmt.parseInt(u64, value, 10) catch {
                    try printer.printf("Invalid seed value: {s}\n", .{value});
                    std.process.exit(1);
                };
                i += 1;
            } else if (std.mem.eql(u8, arg, "-ms")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -ms (milliseconds)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                config.milliseconds = std.fmt.parseInt(u64, value, 10) catch {
                    try printer.printf("Invalid milliseconds value: {s}\n", .{value});
                    std.process.exit(1);
                };
                i += 1;
            } else if (std.mem.eql(u8, arg, "-l")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -l (drop length)\n");
                }

                const value = args[i + 1];
                config.dropLen = std.fmt.parseInt(usize, value, 10) catch {
                    try printer.printf("Invalid drop length value: {s}\n", .{value});
                    std.process.exit(1);
                };
                i += 1;
            } else if (std.mem.eql(u8, arg, "-c")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -c (color)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                if (std.mem.eql(u8, value, "help")) {
                    try config.printEnumOptionsWithTitle(color.Color, "Color", printer);
                    std.process.exit(0);
                }

                config.rainColor = std.meta.stringToEnum(color.Color, value) orelse {
                    try printer.printf("Invalid color: {s}\n", .{value});
                    try config.printEnumOptions(color.Color, printer);
                    std.process.exit(1);
                };
                i += 1;
            } else if (std.mem.eql(u8, arg, "-g")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -g (gradient mode)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                if (std.mem.eql(u8, value, "help")) {
                    try config.printEnumOptionsWithTitle(color.Mode, "Gradient mode", printer);
                    std.process.exit(0);
                }

                config.rainMode = std.meta.stringToEnum(color.Mode, value) orelse {
                    try printer.printf("Invalid gradient mode: {s}\n", .{value});
                    try config.printEnumOptions(color.Mode, printer);
                    std.process.exit(1);
                };
                i += 1;
            } else if (std.mem.eql(u8, arg, "-r")) {
                if (i + 1 >= args.len) {
                    try printer.printf("Missing argument for -r (ASCII mode)\n", .{});
                    std.process.exit(1);
                }

                const value = args[i + 1];
                if (std.mem.eql(u8, value, "help")) {
                    try config.printEnumOptionsWithTitle(ascii.Mode, "ASCII mode", printer);
                    std.process.exit(0);
                }

                config.asciiMode = std.meta.stringToEnum(ascii.Mode, value) orelse {
                    try printer.printf("Invalid ASCII mode: {s}\n", .{value});
                    try config.printEnumOptions(ascii.Mode, printer);
                    std.process.exit(1);
                };
                i += 1;
            } else if (std.mem.eql(u8, arg, "-m")) {
                if (i + 1 >= args.len) {
                    try printer.printf("Missing argument for -m (matrix mode)\n", .{});
                    std.process.exit(1);
                }

                const value = args[i + 1];
                if (std.mem.eql(u8, value, "help")) {
                    try config.printEnumOptionsWithTitle(matrix.Mode, "Matrix", printer);
                    std.process.exit(0);
                }

                config.matrixMode = std.meta.stringToEnum(matrix.Mode, value) orelse {
                    try printer.printf("Invalid matrix mode: {s}\n", .{value});
                    try config.printEnumOptions(matrix.Mode, printer);
                    std.process.exit(1);
                };
                i += 1;
            } else {
                try printer.printf("Unknown argument: {s}\n", .{arg});
                std.process.exit(1);
            }
        }

        const timestamp = std.time.milliTimestamp();
        config.seed = @intCast(timestamp);

        return config;
    }

    fn printEnumOptions(self: *Configuration, comptime T: type, printer: *Printer) !void {
        try self.printEnumOptionsWithTitle(T, "Available", printer);
    }

    fn printEnumOptionsWithTitle(_: *Configuration, comptime T: type, title: [:0]const u8, printer: *Printer) !void {
        const info = @typeInfo(T);
        try printer.printf("{s} options:\n", .{title});
        inline for (info.@"enum".fields) |field| {
            try printer.printf(" - {s}\n", .{field.name});
        }
    }
};

pub fn fromArgs(allocator: std.mem.Allocator, printer: *Printer) !Configuration {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    return Configuration.init(args, printer);
}
