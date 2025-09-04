const std = @import("std");
const code = @import("code.zig");

//41 01 //i32.const 1
//21 02 //local.set 2
//03 40 //loop
//  02 40//loop
//    20 02//local.get 2
//    20 01//local.get 1
//    4a i32.gt_s
//    0d 00 //br_if
//    20 02 //local.get 2
//    20 00 //local.get 0
//    6c
//    21 02
//    0c 01 br 1
//    0b
//  0b
//20 02
//0b

const Instr = enum(u8) {
    //5.4.1 Control Instructions
    unreach = 0,
    nop = 1,
    block = 2,
    loop = 3,
    @"if" = 4,
    @"else" = 5,
    br = 0x0c,
    br_if = 0x0d,
    br_table = 0x0e,
    @"return" = 0x0f,
    call = 0x10,
    call_indirect = 0x11,

    //5.4.2 Reference Instructions

    ref_null = 0xD0,
    ref_is_null = 0xD1,
    ref_func = 0xD2,

    //5.4.3 Parametric Instructions

    drop = 0x1A,
    select = 0x1B,
    select_t = 0x1C,

    //5.4.4 Variable Instructions

    local_get = 0x20,
    local_set = 0x21,
    local_tee = 0x22,
    global_get = 0x23,
    global_set = 0x24,

    //5.4.5 Table Instructions
    table_get = 0x25,
    table_set = 0x26,

    //5.4.6 Memory Instructions
    i32_load = 0x28,
    i64_load = 0x29,
    f32_load = 0x2A,
    f64_load = 0x2B,
    i32_load_8_s = 0x2C,
    i32_load_8_u = 0x2D,
    i32_load_16_s = 0x2E,
    i32_load_16_u = 0x2F,

    i64_load_8_s = 0x30,
    i64_load_8_u = 0x31,
    i64_load_16_s = 0x32,
    i64_load_16_u = 0x33,
    i64_load_32_s = 0x34,
    i64_load_32_u = 0x35,

    i32_store = 0x36,
    i64_store = 0x37,
    f32_store = 0x38,
    f64_store = 0x39,
    i32_store_8 = 0x3A,
    i32_store_16 = 0x3B,
    i64_store_8 = 0x3C,
    i64_store_16 = 0x3D,
    i64_store_32 = 0x3E,

    memory_size = 0x3F,
    memory_grow = 0x40,

    //5.4.7 Numeric Instructions
    i32_const = 0x41,
    i64_const = 0x42,
    f32_const = 0x43,
    f64_const = 0x44,

    variable_length = 0xFC,
};

const Reader = struct {
    data: []const u8,
    idx: usize = 0,

    pub fn nextByte(self: *Reader) ?u8 {
        if (self.idx >= self.data.len) return null;
        defer self.idx += 1;
        return self.data[self.idx];
    }
    pub fn readByte(self: *Reader) !u8 {
        return self.nextByte() orelse error.EOF;
    }
    pub fn read(self: *Reader, comptime T: type) !T {
        errdefer std.log.err("Failure Reading [{f}]{s}", .{ self, @typeName(T) });
        switch (@typeInfo(T)) {
            .@"enum" => |e| {
                const val = try self.read(e.tag_type);
                return try std.meta.intToEnum(T, val);
            },
            .int => |i| {
                if (T == u8) {
                    return try self.readByte();
                }
                switch (i.signedness) {
                    .unsigned => return try std.leb.readUleb128(T, self),
                    .signed => return try std.leb.readIleb128(T, self),
                }
            },
            .float => {
                const bytes = try self.getBytes(@sizeOf(T));
                const ret: *const T = @ptrCast(&bytes);
                return ret.*;
            },
            else => @compileError("TODO"),
        }
    }
    fn getBytes(self: *Reader, len: usize) ![]const u8 {
        if (self.idx + len > self.data.len) return error.NotEnough;
        defer self.idx += len;
        //std.log.err("[{}|{}]Read[{x}]", .{ self.idx, len, self.data[self.idx..][0..len] });
        return self.data[self.idx..][0..len];
    }
    pub fn format(self: Reader, writer: *std.Io.Writer) !void {
        try writer.print("[{}][{x}][{x}]", .{
            self.idx,
            self.data[0..self.idx],
            self.data[self.idx..],
        });
    }
};

const Builder = struct {
    const Block = struct {
        instructions: std.ArrayList(code.Instruction),
    };
    alloc: std.mem.Allocator,
    blocks: std.ArrayList(*Block),
    active_block: u32,
    pub fn init(alloc: std.mem.Allocator) !Builder {
        const b = try alloc.create(Block);
        errdefer alloc.destroy(b);
        b.* = .{ .instructions = std.ArrayList(code.Instruction){} };
        var build = Builder{
            .alloc = alloc,
            .blocks = std.ArrayList(*Block){},
            .active_block = 0,
        };
        try build.blocks.append(alloc, b);
        return build;
    }
    pub fn add(self: *Builder, instr: code.Instruction) !void {
        try self.blocks.items[self.active_block].instructions.append(self.alloc, instr);
        std.log.err("[{}]", .{instr});
    }
    pub fn push_block(self: *Builder) !code.BlockIdx {
        const block_id: u32 = @intCast(self.blocks.items.len);
        const b = try self.alloc.create(Block);
        b.* = .{ .instructions = std.ArrayList(code.Instruction){} };
        try self.blocks.append(self.alloc, b);
        self.active_block = block_id;
        return .{ .idx = block_id };
    }
};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !code.Function {
    var builder = try Builder.init(alloc);
    var reader = Reader{ .data = data };

    while (reader.nextByte()) |byte| {
        const instr = try std.meta.intToEnum(Instr, byte);
        errdefer std.log.err("{}", .{instr});
        switch (instr) {
            .i32_const => {
                try builder.add(.{ .constant = .{ .i32 = try reader.read(i32) } });
            },
            .i64_const => {
                try builder.add(.{ .constant = .{ .i64 = try reader.read(i64) } });
            },
            .f32_const => {
                try builder.add(.{ .constant = .{ .f32 = try reader.read(f32) } });
            },
            .f64_const => {
                try builder.add(.{ .constant = .{ .f64 = try reader.read(f64) } });
            },
            .local_get => {
                try builder.add(.{
                    .local = .{ .idx = try reader.read(u32), .action = .get },
                });
            },
            .local_set => {
                try builder.add(.{
                    .local = .{ .idx = try reader.read(u32), .action = .set },
                });
            },
            .local_tee => {
                try builder.add(.{
                    .local = .{ .idx = try reader.read(u32), .action = .tee },
                });
            },
            .global_get => {
                try builder.add(.{
                    .global = .{ .idx = try reader.read(u32), .action = .get },
                });
            },
            .global_set => {
                try builder.add(.{
                    .global = .{ .idx = try reader.read(u32), .action = .set },
                });
            },
            .block => {
                const block_id = try builder.push_block();
                try builder.add(.{ .block = block_id });
            },
            .loop => {
                const block_id = try builder.push_block();
                try builder.add(.{ .loop = block_id });
            },
            .@"if" => {
                const block_id = try builder.push_block();
                try builder.add(.{ .block = block_id });
            },

            else => return error.TODO,
        }
    }

    return error.TODO;
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const input = "\x41\x00\x21\x02\x03\x40\x02\x40\x20\x02\x20\x01\x4e\x0d\x00\x20\x00\x20\x02\x41\x04\x6c\x6a\x21\x03\x20\x04\x20\x03\x28\x02\x00\x6a\x21\x04\x20\x02\x41\x01\x6a\x21\x02\x0c\x01\x0b\x0b\x20\x04\x0b";
    _ = try parse(input, arena.allocator());
}
