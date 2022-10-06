const std = @import("std");
const app = @import("App.zig");

pub const Buffer = struct {
    alloc: std.mem.Allocator,
    name: std.ArrayList(u8),
    lines: std.ArrayList(std.ArrayList(u8)),

    pub fn fromFile(alloc: std.mem.Allocator, dir: std.fs.Dir, path: []const u8) !Buffer {
        var file = try dir.openFile(path, .{});
        defer file.close();
        const stat = try file.stat();
        var arr = std.ArrayList(u8).init(alloc);
        defer arr.deinit();
        try arr.appendNTimes(0, stat.size);
        _ = try file.readAll(arr.items[0..]);
        var iter = std.mem.split(u8, arr.items, "\n");
        var lines = std.ArrayList(std.ArrayList(u8)).init(alloc);
        errdefer {
            for (lines.items) |li| {
                li.deinit();
            }
            lines.deinit();
        }
        while (iter.next()) |val| {
            var line = std.ArrayList(u8).init(alloc);
            try line.appendSlice(val);
            try lines.append(line);
        }
        var name = std.ArrayList(u8).init(alloc);
        try name.appendSlice(path);
        return Buffer{
            .alloc = alloc,
            .lines = lines,
            .name = name,
        };
    }
    pub fn deinit(self: Buffer) void {
        for (self.lines.items) |li| {
            li.deinit();
        }
        self.lines.deinit();
        self.name.deinit();
    }
    pub fn insert(self: *Buffer, line: usize, col: usize, val: []const u8) !void {
        if (self.lines.items.len > line) {
            if (self.lines.items[line].items.len > col) {
                try self.lines.items[line].insertSlice(col, val);
            }
        }
    }
    pub fn write(self: *Buffer, dir: std.fs.Dir, path: []const u8) !void {
        var array = std.ArrayList(u8).init(self.alloc);
        defer array.deinit();
        var writer = array.writer();
        for (self.lines.items) |line| {
            try std.fmt.format(writer, "{s}\n", .{line.items});
        }
        var file = try dir.createFile(path, .{});
        try file.writeAll(array.items);
    }
};
