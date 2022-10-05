const std = @import("std");
const buffer = @import("Buffer.zig");
const ev = @import("EventLoop.zig");

pub const InitOption = union(enum) {
    openFile: []const u8,
};

const VMIN = 9;
const VTIME = 17;

pub const App = struct {
    tc: std.os.termios,
    alloc: std.mem.Allocator,
    initvals: []const InitOption,
    const infd = std.os.STDIN_FILENO;
    const outfd = std.os.STDOUT_FILENO;
    pub fn init(alloc: std.mem.Allocator, initvals: []const InitOption) !App {
        const tc = try std.os.tcgetattr(infd);
        var newtc = tc;
        newtc.iflag &= ~(std.os.linux.BRKINT | std.os.linux.ICRNL | std.os.linux.INPCK | std.os.linux.ISTRIP | std.os.linux.IXON);
        newtc.oflag &= ~(std.os.linux.OPOST);
        newtc.cflag |= std.os.linux.CS8;
        newtc.lflag &= ~(std.os.linux.ECHO | std.os.linux.ICANON | std.os.linux.IEXTEN | std.os.linux.ISIG);
        newtc.cc[VMIN] = 1;
        try std.os.tcsetattr(infd, .FLUSH, newtc);
        errdefer {
            std.os.tcsetattr(infd, .FLUSH, tc) catch {};
        }
        _ = try std.os.write(outfd, "\x1b[?1049h");
        errdefer {
            _ = std.os.write(outfd, "\x1b[?1049l") catch {};
        }
        _ = try std.os.write(outfd, "test1");
        return App{
            .tc = tc,
            .alloc = alloc,
            .initvals = initvals,
        };
    }
    pub fn deinit(self: App) void {
        std.os.tcsetattr(infd, .FLUSH, self.tc) catch {};
        _ = std.os.write(outfd, "\x1b[?1049l") catch {};
    }
    fn infunc(self: ?*anyopaque, event: *ev.EventLoop, fd: std.os.fd_t) ev.EventFnError!void {
        _ = self;
        var readBuf: [512]u8 = undefined;
        const len = std.os.read(fd, &readBuf) catch return;
        for (readBuf[0..len]) |val| {
            if (val == 'q') {
                event.exit = true;
            } else _ = std.os.write(outfd, &[1]u8{val}) catch return;
        }
    }
    pub fn addEventHandler(self: *App, event: *ev.EventLoop) !void {
        try event.add(.{ .inFn = &infunc, .fd = infd, .ctx = self });
    }
};
