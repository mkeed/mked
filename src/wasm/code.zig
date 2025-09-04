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
};

const typeidx = struct { x: i32 };
const funcidx = struct { x: i32 };
const tableidx = struct { x: i32 };
const memidx = struct { x: i32 };
const globalidx = struct { x: i32 };
const elemidx = struct { x: i32 };
const dataidx = struct { x: i32 };
const localidx = struct { x: i32 };
const labelidx = struct { x: i32 };
