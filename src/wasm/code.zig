const std = @import("std");

pub const Function = struct {
    blocks: []const Block,
};

pub const Block = struct {
    instructions: []const Instruction,
};

pub const ValueType = enum { i32, i64, f32, f64 };

pub const Value = union(ValueType) {
    i32: i32,
    i64: i64,
    f32: f32,
    f64: f64,
};

pub const BlockIdx = struct { idx: u32 };
pub const Instruction = union(enum) {
    local: struct { idx: u32, action: enum { get, set, tee } },
    global: struct { idx: u32, action: enum { get, set } },
    block: BlockIdx,
    loop: BlockIdx,
    @"if": struct { if_block: BlockIdx, else_block: ?BlockIdx },

    branch: struct { labelidx: u32 },
    branch_if: struct { labelidx: u32 },
    //branch_table: struct { labelidx: u32 },
    @"return": void,
    call: struct { func: u32 },
    call_indirect: struct { type: typeidx, table: tableidx },

    constant: Value,
    iunop: struct {
        len: IntLen,
        op: enum { clz, ctz, popcnt },
    },
    ibinop: struct {
        len: IntLen,
        op: enum {
            add,
            sub,
            mul,
            div_s,
            rem_s,
            div_u,
            rem_u,
            @"and",
            @"or",
            xor,
            shl,
            shr_s,
            shr_u,
            rotl,
            rotr,
        },
    },
    itestop: struct {
        len: IntLen,
        op: enum { eqz },
    },
    irelop: struct {
        len: IntLen,
        op: enum { eq, ne, lt_s, lt_u, gt_s, gt_u, le_s, le_u, ge_s, ge_u },
    },
    frelop: struct {
        len: FloatLen,
        op: enum { eq, ne, lt, gt, le, ge },
    },
    load: struct {
        val: ValueType,
        src: ?enum { i8, u8, i16, u16, u32, i32 } = null,
    },
    store: struct {
        val: ValueType,
        dest: ?enum { @"8", @"16", @"32" } = null,
    },
};

const memarg = struct {
    offset: u32,
    @"align": u32,
};

const IntLen = enum { @"32", @"64" };
const FloatLen = enum { @"32", @"64" };

const typeidx = struct { x: i32 };
const funcidx = struct { x: i32 };
const tableidx = struct { x: i32 };
const memidx = struct { x: i32 };
const globalidx = struct { x: i32 };
const elemidx = struct { x: i32 };
const dataidx = struct { x: i32 };
const localidx = struct { x: i32 };
const labelidx = struct { x: i32 };
