const std = @import("std");

pub const EditorContext = struct {
    alloc: std.mem.Allocator,
    dir: std.fs.Dir,
    config: Config,
};
