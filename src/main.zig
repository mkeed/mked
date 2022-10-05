const std = @import("std");
const app = @import("App.zig");
const ev = @import("EventLoop.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    //try app.run(alloc, &.{});

    var loop = ev.EventLoop.init(alloc);
    defer loop.deinit();
    var ed = try app.App.init(alloc, &.{});
    try ed.addEventHandler(&loop);
    defer ed.deinit();

    try loop.run();
}
