const std = @import("std");
const buffer = @import("Buffer.zig");
const ev = @import("EventLoop.zig");
const term = @import("App/terminal.zig");
pub const InitOption = union(enum) {
    openFile: []const u8,
};
pub const KeyCode = enum {
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,
    Home,
    Insert,
    Delete,
    End,
    PgUp,
    PgDn,
    F0,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F19,
    F20,
    Up,
    Down,
    Left,
    Right,
    At,
    LeftBracket,
    Backslash,
    RightBracket,
    Caret,
    Backtick,
    Ins,
    Del,
    Win,
    Apps,
    Space,
    Exclamation,
    DoubleQuote,
    SingleQuote,
    Hash,
    Dollar,
    Percent,
    Ambersand,
    OpenParen,
    CloseParen,
    Asterisk,
    Comma,
    Hyphen,
    Dot,
    ForwardSlash,
    Zero,
    One,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Colon,
    SemiColon,
    LeftAngle,
    RightAngle,
    Equal,
    QuestionMark,
    OpenBracket,
    CloseBracket,
    OpenBrace,
    CloseBrace,
    Pipe,
    Tilde,
    Add,
    Minus,
    Underscore,
    Esc,
    Enter,
    Tab,
};
const VMIN = 9;
const VTIME = 17;

pub const KeyboardEvent = struct {
    ctrl: bool = false,
    shift: bool = false,
    alt: bool = false,
    key: KeyCode,
};

pub const ButtonEvent = enum {
    Left,
    Right,
    Up,
};

pub const MouseEvent = struct {
    button: ButtonEvent,
    x: usize,
    y: usize,
};
pub const KeyEvent = enum {
    Up,
    Down,
    Left,
    Right,
};

pub const InputEvent = union(enum) {
    keyboard: KeyboardEvent,
    mouse: MouseEvent,
};

pub const App = struct {
    tc: std.os.termios,
    alloc: std.mem.Allocator,
    initvals: []const InitOption,
    outwriter: std.fs.File.Writer,
    inputQueue: std.ArrayList(InputEvent),
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
        _ = try std.os.write(outfd, "\x1b[?1049h\x1b[?1002h");
        errdefer {
            _ = std.os.write(outfd, "\x1b[?1049l\x1b[?1002l") catch {};
        }
        _ = try std.os.write(outfd, "test1");
        return App{
            .tc = tc,
            .alloc = alloc,
            .initvals = initvals,
            .outwriter = std.io.getStdOut().writer(),
            .inputQueue = std.ArrayList(InputEvent).init(alloc),
        };
    }
    pub fn deinit(self: App) void {
        std.os.tcsetattr(infd, .FLUSH, self.tc) catch {};
        _ = std.os.write(outfd, "\x1b[?1049l\x1b[?1002l") catch {};
        self.inputQueue.deinit();
    }
    fn infunc(ctx: ?*anyopaque, event: *ev.EventLoop, fd: std.os.fd_t) ev.EventFnError!void {
        var self: *App = @ptrCast(*App, @alignCast(@alignOf(App), ctx orelse return));
        var readBuf: [512]u8 = undefined;
        const len = std.os.read(fd, &readBuf) catch return;
        std.fmt.format(self.outwriter, "[{}]", .{std.fmt.fmtSliceHexUpper(readBuf[0..len])}) catch return;
        _ = event;
        term.read(readBuf[0..len], &self.inputQueue) catch return;
    }
    pub fn addEventHandler(self: *App, event: *ev.EventLoop) !void {
        try event.add(.{ .inFn = &infunc, .fd = infd, .ctx = self });
    }
    pub fn processEvents(self: *App) !bool {
        var result = false;
        defer {
            self.inputQueue.clearRetainingCapacity();
        }
        for (self.inputQueue.items) |item| {
            try std.fmt.format(self.outwriter, "\r\n{}", .{item});
            switch (item) {
                .keyboard => |k| {
                    if (k.key == .Q) result = true;
                },
                else => {},
            }
        }
        return result;
    }
};
