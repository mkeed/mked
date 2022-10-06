const std = @import("std");
const buffer = @import("Buffer.zig");
const ev = @import("EventLoop.zig");
const term = @import("App/terminal.zig");
pub const InitOption = union(enum) {
    openFile: []const u8,
};

pub const KeyCode = enum { A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, Home, Insert, Delete, End, PgUp, PgDn, F0, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18, F19, F20, Up, Down, Left, Right, At, LeftBracket, Backslash, RightBracket, Caret, Backtick, Ins, Del, Win, Apps, Space, Exclamation, DoubleQuote, SingleQuote, Hash, Dollar, Percent, Ambersand, OpenParen, CloseParen, Asterisk, Comma, Hyphen, Dot, ForwardSlash, Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Colon, SemiColon, LeftAngle, RightAngle, Equal, QuestionMark, OpenBracket, CloseBracket, OpenBrace, CloseBrace, Pipe, Tilde, Add, Minus, Underscore, Esc, Enter, Tab };

pub const MenuItem = struct {};

//pub const

pub const Screen = struct {
    menuLine: std.ArrayList(MenuItem),
};

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
    button: u8,
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

pub const GUIImpl = union(enum) {
    term: *term.TerminalIO,

    pub fn init(alloc: std.mem.Allocator, inputQueue: *std.ArrayList(InputEvent)) !GUIImpl {
        return .{
            .term = try term.TerminalIO.init(alloc, inputQueue),
        };
    }
    pub fn deinit(self: GUIImpl) void {
        switch (self) {
            .term => |t| {
                t.deinit();
            },
        }
    }
    pub fn addHandler(self: GUIImpl, event: *ev.EventLoop) !void {
        switch (self) {
            .term => |t| {
                try t.addEventHandler(event);
            },
        }
    }
};

pub const App = struct {
    alloc: std.mem.Allocator,
    initvals: []const InitOption,
    inputQueue: *std.ArrayList(InputEvent),
    buffers: std.ArrayList(buffer.Buffer),
    dir: std.fs.Dir,
    impl: GUIImpl,
    pub fn init(alloc: std.mem.Allocator, initvals: []const InitOption) !App {
        var inputQueue = try alloc.create(std.ArrayList(InputEvent));
        errdefer alloc.destroy(inputQueue);
        inputQueue.* = std.ArrayList(InputEvent).init(alloc);
        errdefer inputQueue.deinit();
        var impl = try GUIImpl.init(alloc, inputQueue);
        errdefer impl.deinit();
        var a = App{
            .alloc = alloc,
            .initvals = initvals,
            .inputQueue = inputQueue,
            .buffers = std.ArrayList(buffer.Buffer).init(alloc),
            .dir = std.fs.cwd(),
            .impl = impl,
        };

        for (initvals) |iv| {
            switch (iv) {
                .openFile => |fp| {
                    var buf = try buffer.Buffer.fromFile(alloc, a.dir, fp);
                    errdefer buf.deinit();
                    try a.buffers.append(buf);
                },
            }
        }
        try a.buffers.items[0].insert(10, 10, "HELLO");
        try a.buffers.items[0].write(a.dir, "LICENSE1");
        return a;
    }
    pub fn deinit(self: App) void {
        self.inputQueue.deinit();
        self.alloc.destroy(self.inputQueue);
        for (self.buffers.items) |b| {
            b.deinit();
        }
        self.buffers.deinit();
        self.impl.deinit();
    }

    pub fn addEventHandler(self: *App, event: *ev.EventLoop) !void {
        try self.impl.addHandler(event);
    }
    pub fn processEvents(self: *App) !bool {
        var outwriter = std.io.getStdOut().writer();
        try std.fmt.format(outwriter, "\x1b[2J\x1b[H\x1b[?25l", .{});
        defer {
            std.fmt.format(outwriter, "\x1b[?25h", .{}) catch {};
        }
        var result = false;
        defer {
            self.inputQueue.clearRetainingCapacity();
        }
        for (self.inputQueue.items) |item| {
            try std.fmt.format(outwriter, "\r\n{}", .{item});
            switch (item) {
                .keyboard => |k| {
                    if (k.key == .Q) result = true;
                },
                else => {},
            }
        }
        for (self.buffers.items) |b| {
            try std.fmt.format(outwriter, "<====={s}====>", .{b.name.items});
            for (b.lines.items) |line, idx| {
                try std.fmt.format(outwriter, "\r\n{:>2}|{s}", .{ idx, line.items });
            }
        }
        return result;
    }
};
