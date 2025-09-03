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
        pub fn format(self: Self, writer: *std.Io.Writer) !void {
            try writer.print("[{}](", .{self.vals.len});
            for (self.vals) |v| {
                if (@hasDecl(T, "format")) {
                    try writer.print("\n({f}),", .{v});
                } else {
                    try writer.print("\n({any}),", .{v});
                }
            }
            try writer.print(")", .{});
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

const name = struct {
    vals: vec(u8),
    pub fn format(self: name, writer: *std.Io.Writer) !void {
        try writer.print("({s})", .{self.vals.vals});
    }
};

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
    pub fn parse(reader: *Reader, alloc: std.mem.Allocator) !functype {
        //std.log.err("{f}", .{reader});
        try reader.expectSlice("\x60");
        return .{
            .args = try reader.parse(resulttype, alloc),
            .ret = try reader.parse(resulttype, alloc),
        };
    }
    args: resulttype,
    ret: resulttype,
};

//5.3.7 Limits
const limits = struct {
    pub fn parse(reader: *Reader, alloc: std.mem.Allocator) !limits {
        _ = alloc;
        const byte = try reader.readByte();
        const min = try reader.read(u32);
        const max: ?u32 = switch (byte) {
            0 => null,
            1 => try reader.read(u32),
            else => return error.InvalidLimit,
        };

        return .{
            .min = min,
            .max = max,
        };
    }
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
    @"export": vec(Export),
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
        pub fn format(self: Import, writer: *std.Io.Writer) !void {
            try writer.print("Import(mod:{f}, nm:{f} d:{})", .{
                self.mod,
                self.nm,
                self.d,
            });
        }
    };

    const Global = struct {
        gt: globaltype,
        e: expr,
    };
    const Export = struct {
        nm: name,
        d: exportdesc,
        const export_pos = enum(u8) {
            func = 0,
            table = 1,
            mem = 2,
            global = 3,
        };
        const exportdesc = union(export_pos) {
            func: funcidx,
            table: tableidx,
            mem: memidx,
            global: globalidx,
        };
        pub fn format(self: Export, writer: *std.Io.Writer) !void {
            try writer.print("{f}:{}", .{ self.nm, self.d });
        }
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
            pub fn parse(
                reader: *Reader,
                alloc: std.mem.Allocator,
            ) !code {
                const size = try reader.read(u32);
                const b = try reader.getBytes(size);
                var subr = Reader{ .data = b };
                const l = try subr.parse(vec(locals), alloc);
                std.log.err("{f}", .{subr});
                return .{
                    .size = size,
                    .code = .{
                        .l = l,
                        .e = .{},
                    },
                };
            }
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

    pub fn format(self: Section, writer: *std.Io.Writer) !void {
        switch (self) {
            inline else => |e| {
                if (@hasDecl(@TypeOf(e), "format")) {
                    try writer.print("[{f}]", .{e});
                } else {
                    try writer.print("[{}]", .{e});
                }
            },
        }
    }
};

const Reader = struct {
    data: []const u8,
    idx: usize = 0,

    fn getBytes(self: *Reader, len: usize) ![]const u8 {
        if (self.idx + len > self.data.len) return error.NotEnough;
        defer self.idx += len;
        //std.log.err("[{}|{}]Read[{x}]", .{ self.idx, len, self.data[self.idx..][0..len] });
        return self.data[self.idx..][0..len];
    }
    pub fn expectSlice(self: *Reader, data: []const u8) !void {
        const bytes = try self.getBytes(data.len);
        if (std.mem.eql(u8, data, bytes) == false) return error.InvalidBytes;
    }

    pub fn readByte(self: *Reader) !u8 {
        if (self.idx >= self.data.len) return error.NotEnough;
        defer self.idx += 1;
        //std.log.err("[{}|{}]ReadByte[{x}]", .{ self.idx, 1, self.data[self.idx] });
        return self.data[self.idx];
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
    pub fn enum_tag(comptime T: type) type {
        switch (@typeInfo(T)) {
            .@"union" => |u| return u.tag_type orelse @compileError("Needs tag type"),
            else => @compileError("Must Be Union"),
        }
    }
    pub fn parseUnion(
        self: *Reader,
        comptime T: type,
        tag: enum_tag(T),
        alloc: std.mem.Allocator,
    ) !T {
        switch (@typeInfo(T)) {
            .@"union" => |u| {
                inline for (u.fields) |f| {
                    if (std.mem.eql(u8, @tagName(tag), f.name)) {
                        return @unionInit(T, f.name, try self.parse(f.type, alloc));
                    }
                }
            },
            else => @compileError("Must be union"),
        }
        unreachable;
    }

    pub fn parse(self: *Reader, comptime T: type, alloc: std.mem.Allocator) !T {
        switch (@typeInfo(T)) {
            .int, .@"enum" => return try self.read(T),
            .@"struct" => |s| {
                if (@hasDecl(T, "parse")) {
                    return try T.parse(self, alloc);
                } else {
                    var ret: T = undefined;
                    inline for (s.fields) |f| {
                        errdefer std.log.err("Failure Reading[{f}] {s}.{s}", .{
                            self,
                            @typeName(T),
                            f.name,
                        });
                        @field(ret, f.name) = try self.parse(f.type, alloc);
                    }
                    return ret;

                    //
                }
            },
            .@"union" => |u| {
                const t = try self.read(u.tag_type orelse @compileError("Need Tag"));
                return try self.parseUnion(T, t, alloc);
            },
            else => {
                @compileLog(T);
                @compileError("TODO");
            },
        }
    }

    pub fn format(self: Reader, writer: *std.Io.Writer) !void {
        try writer.print("[{}][{x}][{x}]", .{
            self.idx,
            self.data[0..self.idx],
            self.data[self.idx..],
        });
    }
};

pub fn read_file(data: []const u8, alloc: std.mem.Allocator) !void {
    var reader = Reader{ .data = data };
    try reader.expectSlice("\x00asm");
    try reader.expectSlice("\x01\x00\x00\x00");

    //std.log.err("{f}", .{reader});
    var sections = std.ArrayList(Section){};
    defer sections.deinit(alloc);
    while (try reader.getSection()) |val| {
        //std.log.err("B:[{}]:L[{x}]", .{ val.id, val.data });
        var subr = Reader{ .data = val.data };
        try sections.append(alloc, try subr.parseUnion(Section, val.id, alloc));
    }
    for (sections.items) |s| {
        std.log.err("{f}", .{s});
    }
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const file = @embedFile("loops.wasm");
    try read_file(file, arena.allocator());
}
