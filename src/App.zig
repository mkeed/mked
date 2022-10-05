const std = @import("std");
const buffer = @import("Buffer.zig");
pub const InitOption = union(enum) {
    openFile: []const u8,
};

const VMIN = 9;
const VTIME = 17;

pub fn run(alloc: std.mem.Allocator, init: []const InitOption) !void {
    _ = init;
    _ = alloc;
    const infd = std.os.STDIN_FILENO;
    const outfd = std.os.STDOUT_FILENO;
    const tc = try std.os.tcgetattr(infd);

    var newtc = tc;
    newtc.iflag &= ~(std.os.linux.BRKINT | std.os.linux.ICRNL | std.os.linux.INPCK | std.os.linux.ISTRIP | std.os.linux.IXON);
    newtc.oflag &= ~(std.os.linux.OPOST);
    newtc.cflag |= std.os.linux.CS8;
    newtc.lflag &= ~(std.os.linux.ECHO | std.os.linux.ICANON | std.os.linux.IEXTEN | std.os.linux.ISIG);
    newtc.cc[VMIN] = 1;
    try std.os.tcsetattr(infd, .FLUSH, newtc);
    defer {
        std.os.tcsetattr(infd, .FLUSH, tc) catch {};
    }
    _ = try std.os.write(outfd, "\x1b[?1049h");
    defer {
        _ = std.os.write(outfd, "\x1b[?1049l") catch {};
    }
}
