const std = @import("std");
const app = @import("App.zig");
const ev = @import("EventLoop.zig");

var logs: ?std.ArrayList(std.ArrayList(u8)) = null;
var logAlloc: ?std.mem.Allocator = null;
pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = scope;
    if (logAlloc) |la| {
        if (logs) |*logs_| {
            var line = std.ArrayList(u8).init(la);
            std.fmt.format(line.writer(), "{s}", .{message_level.asText()}) catch return;
            std.fmt.format(line.writer(), format, args) catch return;
            logs_.append(line) catch return {};
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    logs = std.ArrayList(std.ArrayList(u8)).init(alloc);
    logAlloc = alloc;
    defer {
        var stdErr = std.io.getStdErr().writer();
        if (logs) |l| {
            for (l.items) |val| {
                std.fmt.format(stdErr, "{s}\n", .{val.items}) catch {};
                val.deinit();
            }
            l.deinit();
        }
    }
    //try app.run(alloc, &.{});

    var ed = try app.App.init(alloc, &.{.{ .openFile = "LICENSE" }});
    defer ed.deinit();

    var loop = try ev.EventLoop.init(alloc, &ed);
    defer loop.deinit();

    try loop.run();
}
