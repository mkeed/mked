const std = @import("std");

pub const Buffer = union(enum) {
    fileBacked: FileBackedBuffer,
};

const FileBackedBuffer = struct {
    pub fn read(file: []const u8) !FileBackedBuffer {}
    fileName: std.ArrayList(u8),
    lines: std.ArrayList(std.ArrayList(u8)),
};
