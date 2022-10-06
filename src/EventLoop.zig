const std = @import("std");
const App = @import("App.zig");
pub const EventFnError = error{Fatal};
pub const EventFn = fn (ctx: ?*anyopaque, ev: *EventLoop, fd: std.os.fd_t) EventFnError!void;

pub const EventHandler = struct {
    inFn: ?*const EventFn = null,
    outFn: ?*const EventFn = null,
    errFn: ?*const EventFn = null,
    hupFn: ?*const EventFn = null,
    cleanUpFn: ?*const EventFn = null,
    fd: std.os.fd_t,
    ctx: *anyopaque,
};

pub const EventLoop = struct {
    alloc: std.mem.Allocator,
    events: std.ArrayList(EventHandler),
    pollfds: std.ArrayList(std.os.pollfd),
    app: *App.App,
    exit: bool = false,
    pub fn init(alloc: std.mem.Allocator, app: *App.App) !EventLoop {
        var ev = EventLoop{
            .alloc = alloc,
            .events = std.ArrayList(EventHandler).init(alloc),
            .pollfds = std.ArrayList(std.os.pollfd).init(alloc),
            .app = app,
        };

        try ev.app.addEventHandler(&ev);

        return ev;
    }
    pub fn deinit(self: *EventLoop) void {
        for (self.events.items) |ev| {
            if (ev.cleanUpFn) |func| {
                func(ev.ctx, self, ev.fd) catch {};
            }
        }
        self.events.deinit();
        self.pollfds.deinit();
    }
    pub fn add(self: *EventLoop, handler: EventHandler) !void {
        try self.events.append(handler);
    }
    pub fn remove(self: *EventLoop, fd: std.os.fd_t) void {
        //
        for (self.events.items) |ev, idx| {
            if (ev.fd == fd) {
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
            self.pollfds.clearRetainingCapacity();
            for (self.events.items) |ev| {
                try self.pollfds.append(.{ .fd = ev.fd, .events = std.os.POLL.IN, .revents = 0 });
            }
            const len = try std.os.poll(self.pollfds.items, -1);
            if (len == 0) continue;
            for (self.pollfds.items) |poll| {
                if (poll.revents & std.os.POLL.IN != 0) {
                    for (self.events.items) |handler| {
                        if (handler.fd == poll.fd) {
                            if (handler.inFn) |func| {
                                func(handler.ctx, self, handler.fd) catch |err| {
                                    switch (err) {
                                        EventFnError.Fatal => {
                                            self.exit = true;
                                        },
                                    }
                                };
                            } else {
                                std.log.err("No handler function but events being called removing from list", .{});
                                self.remove(handler.fd);
                            }
                        }
                    }
                }
            }
            if (try self.app.processEvents()) {
                self.exit = true;
            }
        }
    }
};
