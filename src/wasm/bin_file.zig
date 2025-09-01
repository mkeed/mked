const std = @import("std");

fn vec(comptime T: type) type {
    return struct {
        vals: []T,
        const Self = @This();
        pub fn parse(reader: *Reader, alloc: std.mem.Allocator) !Self {
            const n = try reader.read(u32);
            const vals = try alloc.alloc(T, n);
            for (vals) |*v| {
                v.* = try reader.parse(T, alloc);
            }
            return .{
                .vals = vals,
            };
        }
    };
}

const SectionId = enum(u8) {
    custom = 0,
    type = 1,
    import = 2,
    function = 3,
    table = 4,
    memory = 5,
    global = 6,
    @"export" = 7,
    start = 8,
    element = 9,
    code = 10,
    data = 11,
    data_count = 12,
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

//5.2.4 Names

const name = vec(u8);

//5.3.1 Number Types

const numtype = enum(u8) {
    i32 = 0x7F,
    i64 = 0x7E,
    f32 = 0x7D,
    f64 = 0x7C,
};

//5.3.2 Vector Types
const vectype = enum(u8) {
    v128 = 0x7b,
};

//5.3.3 Reference Types
const reftype = enum(u8) {
    funcref = 0x70,
    externref = 0x6f,
};

//5.3.4 Value Types

const valtype = enum(u8) {
    i32 = 0x7F,
    i64 = 0x7E,
    f32 = 0x7D,
    f64 = 0x7C,

    v128 = 0x7b,

    funcref = 0x70,
    externref = 0x6f,
};

//5.3.5 Result Types
const resulttype = vec(valtype);

//5.3.6 Function Types
const functype = struct {
    args: resulttype,
    ret: resulttype,
};

//5.3.7 Limits
const limits = struct {
    min: u32,
    max: ?u32,
};

//5.3.8 Memory Types
const memtype = struct {
    lim: limits,
};

//5.3.9 Table Types
const tabletype = struct {
    et: reftype,
    lim: limits,
};

//5.3.10 Global Types
const globaltype = struct {
    t: valtype,
    mut: enum(u8) { @"const" = 0, @"var" = 1 },
};

const expr = struct {};

const Section = union(SectionId) {
    custom: Custom,
    type: vec(functype),
    import: vec(Import),
    function: vec(typeidx),
    table: vec(tabletype),
    memory: vec(memtype),
    global: Global,
    @"export": Export,
    start: Start,
    element: vec(Element.elem),
    code: vec(Code.code),
    data: Data,
    data_count: DataCount,

    const Custom = struct {};

    const Import = struct {
        mod: name,
        nm: name,
        d: importdesc,
        const importdesc = union(enum) {
            func: typeidx,
            table: tabletype,
            mem: memtype,
            global: globaltype,
        };
    };

    const Global = struct {
        gt: globaltype,
        e: expr,
    };
    const Export = struct {
        nm: name,
        d: exportdesc,
        const exportdesc = union(enum) {
            func: funcidx,
            table: tableidx,
            mem: memidx,
            global: globalidx,
        };
    };
    const Start = struct {
        x: funcidx,
    };
    const Element = struct {
        const elemtype = enum(u32) {
            @"0" = 0,
            @"1" = 1,
            @"2" = 2,
            @"3" = 3,
            @"4" = 4,
            @"5" = 5,
            @"6" = 6,
            @"7" = 7,
        };
        const elem = union(elemtype) {
            @"0": struct { e: expr, y: vec(funcidx) },
            @"1": struct { et: elemkind, y: vec(funcidx) },
            @"2": struct { x: tableidx, e: expr, et: elemkind, y: vec(funcidx) },
            @"3": struct { et: elemkind, y: vec(funcidx) },
            @"4": struct { e: expr, el: vec(expr) },
            @"5": struct { et: reftype, el: vec(expr) },
            @"6": struct { x: tableidx, e: expr, et: reftype, el: vec(expr) },
            @"7": struct { et: reftype, el: vec(expr) },
        };
        const elemkind = enum(u8) { funcref = 0 };
    };
    const Code = struct {
        const code = struct {
            size: u32,
            code: func,
        };
        const func = struct {
            l: vec(locals),
            e: expr,
        };
        const locals = struct {
            n: u32,
            t: valtype,
        };
    };
    const Data = struct {};
    const DataCount = struct {};
};

const Reader = struct {
    data: []const u8,
    idx: usize = 0,

    fn getBytes(self: *Reader, len: usize) ![]const u8 {
        if (self.idx + len > self.data.len) return error.NotEnough;
        defer self.idx += len;
        return self.data[self.idx..][0..len];
    }
    pub fn expectSlice(self: *Reader, data: []const u8) !void {
        const bytes = try self.getBytes(data.len);
        if (std.mem.eql(u8, data, bytes) == false) return error.InvalidBytes;
    }

    pub fn readByte(self: *Reader) !u8 {
        if (self.idx >= self.data.len) return error.NotEnough;
        defer self.idx += 1;
        return self.data[self.idx];
    }

    pub fn read(self: *Reader, comptime T: type) !T {
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
            else => @compileError("TODO"),
        }
    }

    pub fn getSection(self: *Reader) !?struct { id: SectionId, data: []const u8 } {
        if (self.idx >= self.data.len) return null;
        const n = try self.read(SectionId);

        const num_bytes = try self.read(u32);
        const bytes = try self.getBytes(num_bytes);
        return .{
            .id = n,
            .data = bytes,
        };
    }

    pub fn parse(self: *Reader, comptime T: type, alloc: std.mem.Allocator) !T {
        switch (@typeInfo(T)) {
            .int => return try self.read(T),
            .@"struct" => |_| {
                if (@hasDecl(T, "parse")) {
                    return try T.parse(self, alloc);
                } else {
                    @compileError("TODO");
                    //
                }
            },
            else => @compileError("TODO"),
        }
    }

    pub fn format(self: Reader, writer: *std.Io.Writer) !void {
        try writer.print("[{}]{x}", .{ self.idx, self.data[self.idx..] });
    }
};

pub fn read_file(data: []const u8, alloc: std.mem.Allocator) !void {
    var reader = Reader{ .data = data };
    try reader.expectSlice("\x00asm");
    try reader.expectSlice("\x01\x00\x00\x00");

    std.log.err("{f}", .{reader});

    while (try reader.getSection()) |val| {
        std.log.err("B:[{}]:L[{x}]", .{ val.id, val.data });
        switch (val.id) {
            .type => {
                const t = try reader.parse(vec(functype), alloc);
                _ = t;
            },
            else => {},
        }
    }
}

test {
    const file = @embedFile("add.wasm");
    try read_file(file, std.testing.allocator);
}
