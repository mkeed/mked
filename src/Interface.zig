const std = @import("std");

pub const Request = union(enum) {
    open_project: struct { dir: []const u8 },
    search: struct { pattern: []const u8 },
};

pub const Result = union(enum) {};
