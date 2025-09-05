const std = @import("std");

pub fn encode(comptime T: type, writer: *std.Io.Writer) !void {
    _ = writer;
    switch (@typeInfo(T)) {
        .int => |i| {
            _ = i;
        },
    }
}

pub fn decode(reader: *std.Io.Reader) !void {
    const tag = try reader.takeByte();
    if ((tag & 0b1000_0000) == 0) {
        std.log.err("Int:{}", .{@as(u7, @truncate(tag))});
    } else if (@as(u4, @truncate(tag >> 4)) == 0b1000) {
        std.log.err("FixMap:{}", .{@as(u4, @truncate(tag))});
    } else if (@as(u4, @truncate(tag >> 4)) == 0b1001) {
        std.log.err("FixArray:{}", .{@as(u4, @truncate(tag))});
    } else if (@as(u3, @truncate(tag >> 5)) == 0b101) {
        std.log.err("FixStr:{}", .{@as(u5, @truncate(tag))});
    } else if (@as(u3, @truncate(tag >> 5)) == 0b111) {
        std.log.err("NegativeInt:{}", .{@as(u5, @truncate(tag))});
    } else {
        switch (std.meta.intToEnum(Tag, tag) catch unreachable) {
            .nil => {},
            .false => {},
            .true => {},
            .bin_8 => {},
            .bin_16 => {},
            .bin_32 => {},
            .ext_8 => {},
            .ext_16 => {},
            .ext_32 => {},
            .float_32 => {},
            .float_64 => {},
            .uint_8 => std.log.err("int:{}", .{try reader.takeInt(u8, .big)}),
            .uint_16 => std.log.err("int:{}", .{try reader.takeInt(u16, .big)}),
            .uint_32 => std.log.err("int:{}", .{try reader.takeInt(u32, .big)}),
            .uint_64 => std.log.err("int:{}", .{try reader.takeInt(u64, .big)}),
            .int_8 => std.log.err("int:{}", .{try reader.takeInt(i8, .big)}),
            .int_16 => std.log.err("int:{}", .{try reader.takeInt(i16, .big)}),
            .int_32 => std.log.err("int:{}", .{try reader.takeInt(i32, .big)}),
            .int_64 => std.log.err("int:{}", .{try reader.takeInt(i64, .big)}),
            .fixext_1 => {},
            .fixext_2 => {},
            .fixext_4 => {},
            .fixext_8 => {},
            .fixext_16 => {},
            .str_8 => std.log.err("str:{}", .{try reader.takeInt(u8, .big)}),
            .str_16 => {},
            .str_32 => {},
            .array_16 => {},
            .array_32 => {},
            .map_16 => {},
            .map_32 => {},
        }
    }
}
const Tag = enum(u8) {
    nil = 0xc0,
    false = 0xc2,
    true = 0xc3,
    bin_8 = 0xc4,
    bin_16 = 0xc5,
    bin_32 = 0xc6,
    ext_8 = 0xc7,
    ext_16 = 0xc8,
    ext_32 = 0xc9,
    float_32 = 0xca,
    float_64 = 0xcb,
    uint_8 = 0xcc,
    uint_16 = 0xcd,
    uint_32 = 0xce,
    uint_64 = 0xcf,
    int_8 = 0xd0,
    int_16 = 0xd1,
    int_32 = 0xd2,
    int_64 = 0xd3,
    fixext_1 = 0xd4,
    fixext_2 = 0xd5,
    fixext_4 = 0xd6,
    fixext_8 = 0xd7,
    fixext_16 = 0xd8,
    str_8 = 0xd9,
    str_16 = 0xda,
    str_32 = 0xdb,
    array_16 = 0xdc,
    array_32 = 0xdd,
    map_16 = 0xde,
    map_32 = 0xdf,
};

test {
    const tc = struct {
        input: []const u8,
    };

    const tests = [_]tc{
        .{ .input = "\x00" },
    };

    for (tests) |t| {
        var reader = std.Io.Reader.fixed(t.input);
        try decode(&reader);
    }
}
