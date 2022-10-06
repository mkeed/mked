const std = @import("std");
const app = @import("App.zig");
const ev = @import("EventLoop.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    //try app.run(alloc, &.{});

    var ed = try app.App.init(alloc, &.{});
    defer ed.deinit();

    var loop = try ev.EventLoop.init(alloc, &ed);
    defer loop.deinit();

    try loop.run();
}
