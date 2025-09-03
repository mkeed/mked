const std = @import("std");

pub const Function = struct {
    blocks: []const Block,
};

pub const Block = struct {
    instructions: []const Instrucion,
};

pub const BlockIdx = struct { idx: u32 };
pub const Instruction = union(enum) {
    local: enum { get, set, tee },
    global: enum { get, set },
    block: BlockIdx,
    loop: BlockIdx,
    @"if": struct { if_block: BlockIdx, else_block: ?BlockIdx },

    branch: struct { labelidx: u32 },
    branch_if: struct { labelidx: u32 },
    //branch_table: struct { labelidx: u32 },
    @"return": void,
    call: struct { func: u32 },
    call_indirect: struct { type: typeidx, table: tableidx },
};
