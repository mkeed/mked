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
    end_block = 0x0b,
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

    i32_eqz = 0x45,
    i32_eq = 0x46,
    i32_ne = 0x47,
    i32_lt_s = 0x48,
    i32_lt_u = 0x49,
    i32_gt_s = 0x4A,
    i32_gt_u = 0x4B,
    i32_le_s = 0x4C,
    i32_le_u = 0x4D,
    i32_ge_s = 0x4E,
    i32_ge_u = 0x4F,
    i64_eqz = 0x50,
    i64_eq = 0x51,
    i64_ne = 0x52,
    i64_lt_s = 0x53,
    i64_lt_u = 0x54,
    i64_gt_s = 0x55,
    i64_gt_u = 0x56,
    i64_le_s = 0x57,
    i64_le_u = 0x58,
    i64_ge_s = 0x59,
    i64_ge_u = 0x5A,
    f32_eq = 0x5B,
    f32_ne = 0x5C,
    f32_lt = 0x5D,
    f32_gt = 0x5E,
    f32_le = 0x5F,
    f32_ge = 0x60,
    f64_eq = 0x61,
    f64_ne = 0x62,
    f64_lt = 0x63,
    f64_gt = 0x64,
    f64_le = 0x65,
    f64_ge = 0x66,
    i32_clz = 0x67,
    i32_ctz = 0x68,
    i32_popcnt = 0x69,
    i32_add = 0x6A,
    i32_sub = 0x6B,
    i32_mul = 0x6C,
    i32_div_s = 0x6D,
    i32_div_u = 0x6E,
    i32_rem_s = 0x6F,
    i32_rem_u = 0x70,
    i32_and = 0x71,
    i32_or = 0x72,
    i32_xor = 0x73,
    i32_shl = 0x74,
    i32_shr_s = 0x75,
    i32_shr_u = 0x76,
    i32_rotl = 0x77,
    i32_rotr = 0x78,
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
            .@"struct" => |s| {
                var ret: T = undefined;
                inline for (s.fields) |f| {
                    @field(ret, f.name) = try self.read(f.type);
                }

                return ret;
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
        parent_block: ?u32,
    };
    alloc: std.mem.Allocator,
    blocks: std.ArrayList(*Block),
    active_block: u32,
    pub fn init(alloc: std.mem.Allocator) !Builder {
        const b = try alloc.create(Block);
        errdefer alloc.destroy(b);
        b.* = .{ .instructions = std.ArrayList(code.Instruction){}, .parent_block = null };
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
        const parent = self.active_block;
        const block_id: u32 = @intCast(self.blocks.items.len);
        const b = try self.alloc.create(Block);
        b.* = .{ .instructions = std.ArrayList(code.Instruction){}, .parent_block = parent };
        try self.blocks.append(self.alloc, b);
        self.active_block = block_id;
        return .{ .idx = block_id };
    }
    pub fn pop_block(self: *Builder) ?u32 {
        std.log.err("pop block", .{});
        const block = self.blocks.items[self.active_block];
        if (block.parent_block) |pb| {
            self.active_block = pb;
        }
        return block.parent_block;
    }
};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !code.expr {
    var builder = try Builder.init(alloc);
    var reader = Reader{ .data = data };

    while (reader.nextByte()) |byte| {
        errdefer std.log.err("Byte[{x}]", .{byte});
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
                const block_type = try reader.readByte();
                if (block_type != 0x40) return error.TODO;
                try builder.add(.{ .block = block_id });
            },
            .loop => {
                const block_id = try builder.push_block();
                const block_type = try reader.readByte();
                if (block_type != 0x40) return error.TODO;
                try builder.add(.{ .loop = block_id });
            },
            .@"if" => {
                const block_id = try builder.push_block();
                const block_type = try reader.readByte();
                if (block_type != 0x40) return error.TODO;
                try builder.add(.{ .block = block_id });
            },
            .br_if => {
                try builder.add(.{ .branch_if = .{ .labelidx = try reader.read(u32) } });
            },
            .br => {
                try builder.add(.{ .branch = .{ .labelidx = try reader.read(u32) } });
            },
            .end_block => {
                if (builder.pop_block()) |pb| {
                    _ = pb;
                } else {
                    const func = code.expr{
                        .blocks = try alloc.alloc(code.Block, builder.blocks.items.len),
                    };
                    for (func.blocks, 0..) |*b, idx| {
                        b.* = .{
                            .instructions = try builder.blocks.items[idx].instructions.toOwnedSlice(alloc),
                        };
                    }
                    return func;
                }
            },
            .i32_eqz => try builder.add(.{ .itestop = .{ .len = .@"32", .op = .eqz } }),
            .i32_eq => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .eq } }),
            .i32_ne => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .ne } }),
            .i32_lt_s => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .lt_s } }),
            .i32_lt_u => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .lt_u } }),
            .i32_gt_s => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .gt_s } }),
            .i32_gt_u => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .gt_u } }),
            .i32_le_s => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .le_s } }),
            .i32_le_u => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .le_u } }),
            .i32_ge_s => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .ge_s } }),
            .i32_ge_u => try builder.add(.{ .irelop = .{ .len = .@"32", .op = .ge_u } }),

            .i64_eqz => try builder.add(.{ .itestop = .{ .len = .@"64", .op = .eqz } }),
            .i64_eq => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .eq } }),
            .i64_ne => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .ne } }),
            .i64_lt_s => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .lt_s } }),
            .i64_lt_u => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .lt_u } }),
            .i64_gt_s => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .gt_s } }),
            .i64_gt_u => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .gt_u } }),
            .i64_le_s => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .le_s } }),
            .i64_le_u => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .le_u } }),
            .i64_ge_s => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .ge_s } }),
            .i64_ge_u => try builder.add(.{ .irelop = .{ .len = .@"64", .op = .ge_u } }),

            .f32_eq => try builder.add(.{ .frelop = .{ .len = .@"32", .op = .eq } }),
            .f32_ne => try builder.add(.{ .frelop = .{ .len = .@"32", .op = .ne } }),
            .f32_lt => try builder.add(.{ .frelop = .{ .len = .@"32", .op = .lt } }),
            .f32_gt => try builder.add(.{ .frelop = .{ .len = .@"32", .op = .gt } }),
            .f32_le => try builder.add(.{ .frelop = .{ .len = .@"32", .op = .le } }),
            .f32_ge => try builder.add(.{ .frelop = .{ .len = .@"32", .op = .ge } }),

            .f64_eq => try builder.add(.{ .frelop = .{ .len = .@"64", .op = .eq } }),
            .f64_ne => try builder.add(.{ .frelop = .{ .len = .@"64", .op = .ne } }),
            .f64_lt => try builder.add(.{ .frelop = .{ .len = .@"64", .op = .lt } }),
            .f64_gt => try builder.add(.{ .frelop = .{ .len = .@"64", .op = .gt } }),
            .f64_le => try builder.add(.{ .frelop = .{ .len = .@"64", .op = .le } }),
            .f64_ge => try builder.add(.{ .frelop = .{ .len = .@"64", .op = .ge } }),

            .i32_clz => try builder.add(.{ .iunop = .{ .len = .@"32", .op = .clz } }),
            .i32_ctz => try builder.add(.{ .iunop = .{ .len = .@"32", .op = .ctz } }),
            .i32_popcnt => try builder.add(.{ .iunop = .{ .len = .@"32", .op = .popcnt } }),

            .i32_add => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .add } }),
            .i32_sub => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .sub } }),
            .i32_mul => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .mul } }),
            .i32_div_s => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .div_s } }),
            .i32_div_u => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .div_u } }),
            .i32_rem_s => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .rem_s } }),
            .i32_rem_u => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .rem_u } }),
            .i32_and => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .@"and" } }),
            .i32_or => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .@"or" } }),
            .i32_xor => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .xor } }),
            .i32_shl => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .shl } }),
            .i32_shr_s => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .shr_s } }),
            .i32_shr_u => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .shr_u } }),
            .i32_rotl => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .rotl } }),
            .i32_rotr => try builder.add(.{ .ibinop = .{ .len = .@"32", .op = .rotr } }),

            .i32_load => try builder.add(.{ .load = .{
                .val = .i32,
                .mem = try reader.read(code.memarg),
            } }),
            .i64_load => try builder.add(.{ .load = .{
                .val = .i64,
                .mem = try reader.read(code.memarg),
            } }),
            .f32_load => try builder.add(.{ .load = .{
                .val = .f32,
                .mem = try reader.read(code.memarg),
            } }),
            .f64_load => try builder.add(.{ .load = .{
                .val = .f64,
                .mem = try reader.read(code.memarg),
            } }),
            .i32_load_8_s => try builder.add(.{ .load = .{
                .val = .i32,
                .src = .i8,
                .mem = try reader.read(code.memarg),
            } }),
            .i32_load_8_u => try builder.add(.{ .load = .{
                .val = .i32,
                .src = .u8,
                .mem = try reader.read(code.memarg),
            } }),
            .i32_load_16_s => try builder.add(.{ .load = .{
                .val = .i32,
                .src = .i16,
                .mem = try reader.read(code.memarg),
            } }),
            .i32_load_16_u => try builder.add(.{ .load = .{
                .val = .i32,
                .src = .u16,
                .mem = try reader.read(code.memarg),
            } }),
            .i64_load_8_s => try builder.add(.{ .load = .{
                .val = .i64,
                .src = .i8,
                .mem = try reader.read(code.memarg),
            } }),
            .i64_load_8_u => try builder.add(.{ .load = .{
                .val = .i64,
                .src = .u8,
                .mem = try reader.read(code.memarg),
            } }),
            .i64_load_16_s => try builder.add(.{ .load = .{
                .val = .i64,
                .src = .i16,
                .mem = try reader.read(code.memarg),
            } }),
            .i64_load_16_u => try builder.add(.{ .load = .{
                .val = .i64,
                .src = .u16,
                .mem = try reader.read(code.memarg),
            } }),
            .i64_load_32_s => try builder.add(.{ .load = .{
                .val = .i64,
                .src = .i32,
                .mem = try reader.read(code.memarg),
            } }),
            .i64_load_32_u => try builder.add(.{ .load = .{
                .val = .i64,
                .src = .u32,
                .mem = try reader.read(code.memarg),
            } }),
            .i32_store => try builder.add(.{ .store = .{
                .val = .i32,
                .mem = try reader.read(code.memarg),
            } }),
            .i64_store => try builder.add(.{ .store = .{
                .val = .i64,
                .mem = try reader.read(code.memarg),
            } }),
            .f32_store => try builder.add(.{ .store = .{
                .val = .f32,
                .mem = try reader.read(code.memarg),
            } }),
            .f64_store => try builder.add(.{ .store = .{
                .val = .f64,
                .mem = try reader.read(code.memarg),
            } }),
            .i32_store_8 => try builder.add(.{ .store = .{
                .val = .i32,
                .dest = .@"8",
                .mem = try reader.read(code.memarg),
            } }),
            .i32_store_16 => try builder.add(.{ .store = .{
                .val = .i32,
                .dest = .@"16",
                .mem = try reader.read(code.memarg),
            } }),
            .i64_store_8 => try builder.add(.{ .store = .{
                .val = .i64,
                .dest = .@"8",
                .mem = try reader.read(code.memarg),
            } }),
            .i64_store_16 => try builder.add(.{ .store = .{
                .val = .i64,
                .dest = .@"16",
                .mem = try reader.read(code.memarg),
            } }),
            .i64_store_32 => try builder.add(.{ .store = .{
                .val = .i64,
                .dest = .@"32",
                .mem = try reader.read(code.memarg),
            } }),
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
