const std = @import("std");

pub const EventFnError = error{Fatal};
pub const EventFn = fn (ctx: ?*anyopaque, ev: *EventLoop, fd: std.os.fd_t) EventFnError!void;

pub const EventHandler = struct {
    inFn: ?*const EventFn,
    outFn: ?*const EventFn,
    errFn: ?*const EventFn,
    hupFn: ?*const EventFn,
    cleanUpFn: ?*const EventFn,
    fd: std.os.fd_t,
    ctx: *anyopaque,
};

pub const EventLoop = struct {
    alloc: std.mem.Allocator,
    events: std.ArrayList(EventHandler),
    pollfds: std.ArrayList(std.os.pollfd),
    exit: bool = false,
    pub fn init(alloc: std.mem.Allocator) EventLoop {
        return EventLoop{
            .alloc = alloc,
            .events = std.ArrayList(EventHandler).init(alloc),
            .pollfds = std.ArrayList(std.os.pollfd).init(alloc),
        };
    }
    pub fn deinit(self: *EventLoop) void {
        for (self.events.items) |ev| {
            if (ev.cleanUpFn) |func| {
                func(ev.ctx, self, ev.fd) catch {};
            }
        }
        self.events.deinit();
    }
    pub fn add(self: *EventLoop, handler: EventHandler) !void {
        try self.events.append(handler);
    }
    pub fn remove(self: *EventLoop, fd: std.os.fd_t, ctx: *anyopaque) void {
        //
        for (self.events.items) |ev, idx| {
            if (ev.fd == fd and ev.ctx == ctx) {
                _ = self.events.swapRemove(idx);
                return;
            }
        }
    }
    pub fn exit(self: *EventLoop) void {
        self.exit = true;
    }
    pub fn run(self: *EventLoop) !void {
        while (!self.exit) {
            //
            return;

            // var polls = [1]std.os.pollfd{
            //     .{ .fd = infd, .events = std.os.POLL.IN, .revents = 0 },
            // };
            // _ = try std.os.poll(&polls, -1);
        }
    }
};
