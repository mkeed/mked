const std = @import("std");
const App = @import("../App.zig");
const ev = @import("../EventLoop.zig");
const TerminalCode = struct {
    seq: []const u8,
    key: App.InputEvent,
};

const escapeCodes = [_]TerminalCode{
    .{ .seq = "[A", .key = .{ .keyboard = .{ .key = .Up } } },
    .{ .seq = "[B", .key = .{ .keyboard = .{ .key = .Down } } },
    .{ .seq = "[C", .key = .{ .keyboard = .{ .key = .Right } } },
    .{ .seq = "[D", .key = .{ .keyboard = .{ .key = .Left } } },
    .{ .seq = "[F", .key = .{ .keyboard = .{ .key = .End } } },
    //.{.seq = "[H", .key = .{.keyboard = .Pos1}},
    .{ .seq = "[2~", .key = .{ .keyboard = .{ .key = .Ins } } },
    .{ .seq = "[3~", .key = .{ .keyboard = .{ .key = .Del } } },
    .{ .seq = "[5~", .key = .{ .keyboard = .{ .key = .PgUp } } },
    .{ .seq = "[6~", .key = .{ .keyboard = .{ .key = .PgDn } } },
    .{ .seq = "OP", .key = .{ .keyboard = .{ .key = .F1 } } },
    .{ .seq = "OQ", .key = .{ .keyboard = .{ .key = .F2 } } },
    .{ .seq = "OR", .key = .{ .keyboard = .{ .key = .F3 } } },
    .{ .seq = "OS", .key = .{ .keyboard = .{ .key = .F4 } } },
    .{ .seq = "[15~", .key = .{ .keyboard = .{ .key = .F5 } } },
    .{ .seq = "[17~", .key = .{ .keyboard = .{ .key = .F6 } } },
    .{ .seq = "[18~", .key = .{ .keyboard = .{ .key = .F7 } } },
    .{ .seq = "[19~", .key = .{ .keyboard = .{ .key = .F8 } } },
    .{ .seq = "[20~", .key = .{ .keyboard = .{ .key = .F9 } } },
    .{ .seq = "[21~", .key = .{ .keyboard = .{ .key = .F10 } } },
    .{ .seq = "[23~", .key = .{ .keyboard = .{ .key = .F11 } } },
    .{ .seq = "[24~", .key = .{ .keyboard = .{ .key = .F12 } } },
    //                 '[29~': 'Apps',
    .{ .seq = "[34~", .key = .{ .keyboard = .{ .key = .Win } } },
    .{ .seq = "[1;2A", .key = .{ .keyboard = .{ .shift = true, .key = .Up } } },
    .{ .seq = "[1;2B", .key = .{ .keyboard = .{ .shift = true, .key = .Down } } },
    .{ .seq = "[1;2C", .key = .{ .keyboard = .{ .shift = true, .key = .Right } } },
    .{ .seq = "[1;2D", .key = .{ .keyboard = .{ .shift = true, .key = .Left } } },
    .{ .seq = "[1;2F", .key = .{ .keyboard = .{ .shift = true, .key = .End } } },
    //.{ .seq = "[1;2H", .key = .{ .keyboard = .{ .key = .S - Pos1 } } },
    .{ .seq = "[2;2~", .key = .{ .keyboard = .{ .shift = true, .key = .Ins } } },
    .{ .seq = "[3;2~", .key = .{ .keyboard = .{ .shift = true, .key = .Del } } },
    .{ .seq = "[5;2~", .key = .{ .keyboard = .{ .shift = true, .key = .PgUp } } },
    .{ .seq = "[6;2~", .key = .{ .keyboard = .{ .shift = true, .key = .PgDn } } },
    .{ .seq = "[1;2P", .key = .{ .keyboard = .{ .shift = true, .key = .F1 } } },
    .{ .seq = "[1;2Q", .key = .{ .keyboard = .{ .shift = true, .key = .F2 } } },
    .{ .seq = "[1;2R", .key = .{ .keyboard = .{ .shift = true, .key = .F3 } } },
    .{ .seq = "[1;2S", .key = .{ .keyboard = .{ .shift = true, .key = .F4 } } },
    .{ .seq = "[15;2~", .key = .{ .keyboard = .{ .shift = true, .key = .F5 } } },
    .{ .seq = "[17;2~", .key = .{ .keyboard = .{ .shift = true, .key = .F6 } } },
    .{ .seq = "[18;2~", .key = .{ .keyboard = .{ .shift = true, .key = .F7 } } },
    .{ .seq = "[19;2~", .key = .{ .keyboard = .{ .shift = true, .key = .F8 } } },
    .{ .seq = "[20;2~", .key = .{ .keyboard = .{ .shift = true, .key = .F9 } } },
    .{ .seq = "[21;2~", .key = .{ .keyboard = .{ .shift = true, .key = .F10 } } },
    .{ .seq = "[23;2~", .key = .{ .keyboard = .{ .shift = true, .key = .F11 } } },
    .{ .seq = "[24;2~", .key = .{ .keyboard = .{ .shift = true, .key = .F12 } } },
    .{ .seq = "[29;2~", .key = .{ .keyboard = .{ .shift = true, .key = .Apps } } },
    .{ .seq = "[34;2~", .key = .{ .keyboard = .{ .shift = true, .key = .Win } } },
    .{ .seq = "[1;3A", .key = .{ .keyboard = .{ .shift = true, .key = .Up } } },
    .{ .seq = "[1;3B", .key = .{ .keyboard = .{ .alt = true, .key = .Down } } },
    .{ .seq = "[1;3C", .key = .{ .keyboard = .{ .alt = true, .key = .Right } } },
    .{ .seq = "[1;3D", .key = .{ .keyboard = .{ .alt = true, .key = .Left } } },
    .{ .seq = "[1;3F", .key = .{ .keyboard = .{ .alt = true, .key = .End } } },
    //    .{ .seq = "[1;3H", .key = .{ .keyboard = .{ .key = .M - Pos1 } } },
    .{ .seq = "[2;3~", .key = .{ .keyboard = .{ .alt = true, .key = .Ins } } },
    .{ .seq = "[3;3~", .key = .{ .keyboard = .{ .alt = true, .key = .Del } } },
    .{ .seq = "[5;3~", .key = .{ .keyboard = .{ .alt = true, .key = .PgUp } } },
    .{ .seq = "[6;3~", .key = .{ .keyboard = .{ .alt = true, .key = .PgDn } } },
    .{ .seq = "[1;3P", .key = .{ .keyboard = .{ .alt = true, .key = .F1 } } },
    .{ .seq = "[1;3Q", .key = .{ .keyboard = .{ .alt = true, .key = .F2 } } },
    .{ .seq = "[1;3R", .key = .{ .keyboard = .{ .alt = true, .key = .F3 } } },
    .{ .seq = "[1;3S", .key = .{ .keyboard = .{ .alt = true, .key = .F4 } } },
    .{ .seq = "[15;3~", .key = .{ .keyboard = .{ .alt = true, .key = .F5 } } },
    .{ .seq = "[17;3~", .key = .{ .keyboard = .{ .alt = true, .key = .F6 } } },
    .{ .seq = "[18;3~", .key = .{ .keyboard = .{ .alt = true, .key = .F7 } } },
    .{ .seq = "[19;3~", .key = .{ .keyboard = .{ .alt = true, .key = .F8 } } },
    .{ .seq = "[20;3~", .key = .{ .keyboard = .{ .alt = true, .key = .F9 } } },
    .{ .seq = "[21;3~", .key = .{ .keyboard = .{ .alt = true, .key = .F10 } } },
    .{ .seq = "[23;3~", .key = .{ .keyboard = .{ .alt = true, .key = .F11 } } },
    .{ .seq = "[24;3~", .key = .{ .keyboard = .{ .alt = true, .key = .F12 } } },
    .{ .seq = "[29;3~", .key = .{ .keyboard = .{ .alt = true, .key = .Apps } } },
    .{ .seq = "[34;3~", .key = .{ .keyboard = .{ .alt = true, .key = .Win } } },
    .{ .seq = "[1;5A", .key = .{ .keyboard = .{ .ctrl = true, .key = .Up } } },
    .{ .seq = "[1;5B", .key = .{ .keyboard = .{ .ctrl = true, .key = .Down } } },
    .{ .seq = "[1;5C", .key = .{ .keyboard = .{ .ctrl = true, .key = .Right } } },
    .{ .seq = "[1;5D", .key = .{ .keyboard = .{ .ctrl = true, .key = .Left } } },
    .{ .seq = "[1;5F", .key = .{ .keyboard = .{ .ctrl = true, .key = .End } } },
    //.{ .seq = "[1;5H", .key = .{ .keyboard = .{ .key = .C - Pos1 } } },
    .{ .seq = "[2;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .Ins } } },
    .{ .seq = "[3;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .Del } } },
    .{ .seq = "[5;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .PgUp } } },
    .{ .seq = "[6;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .PgDn } } },
    .{ .seq = "[1;5P", .key = .{ .keyboard = .{ .ctrl = true, .key = .F1 } } },
    .{ .seq = "[1;5Q", .key = .{ .keyboard = .{ .ctrl = true, .key = .F2 } } },
    .{ .seq = "[1;5R", .key = .{ .keyboard = .{ .ctrl = true, .key = .F3 } } },
    .{ .seq = "[1;5S", .key = .{ .keyboard = .{ .ctrl = true, .key = .F4 } } },
    .{ .seq = "[15;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .F5 } } },
    .{ .seq = "[17;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .F6 } } },
    .{ .seq = "[18;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .F7 } } },
    .{ .seq = "[19;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .F8 } } },
    .{ .seq = "[20;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .F9 } } },
    .{ .seq = "[21;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .F10 } } },
    .{ .seq = "[23;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .F11 } } },
    .{ .seq = "[24;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .F12 } } },
    .{ .seq = "[29;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .Apps } } },
    .{ .seq = "[34;5~", .key = .{ .keyboard = .{ .ctrl = true, .key = .Win } } },
    .{ .seq = "[1;6A", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .Up } } },
    .{ .seq = "[1;6B", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .Down } } },
    .{ .seq = "[1;6C", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .Right } } },
    .{ .seq = "[1;6D", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .Left } } },
    .{ .seq = "[1;6F", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .End } } },
    //.{ .seq = "[1;6H", .key = .{ .keyboard = .{ .key = .S - C - Pos1 } } },
    .{ .seq = "[2;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .Ins } } },
    .{ .seq = "[3;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .Del } } },
    .{ .seq = "[5;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .PgUp } } },
    .{ .seq = "[6;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .PgDn } } },
    .{ .seq = "[1;6P", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F1 } } },
    .{ .seq = "[1;6Q", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F2 } } },
    .{ .seq = "[1;6R", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F3 } } },
    .{ .seq = "[1;6S", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F4 } } },
    .{ .seq = "[15;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F5 } } },
    .{ .seq = "[17;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F6 } } },
    .{ .seq = "[18;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F7 } } },
    .{ .seq = "[19;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F8 } } },
    .{ .seq = "[20;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F9 } } },
    .{ .seq = "[21;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F10 } } },
    .{ .seq = "[23;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F11 } } },
    .{ .seq = "[24;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .F12 } } },
    .{ .seq = "[29;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .Apps } } },
    .{ .seq = "[34;6~", .key = .{ .keyboard = .{ .ctrl = true, .shift = true, .key = .Win } } },
    .{ .seq = "[1;7A", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .Up } } },
    .{ .seq = "[1;7B", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .Down } } },
    .{ .seq = "[1;7C", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .Right } } },
    .{ .seq = "[1;7D", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .Left } } },
    .{ .seq = "[1;7F", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .End } } },
    //.{ .seq = "[1;7H", .key = .{ .keyboard = .{ .key = .C - M - Pos1 } } },
    .{ .seq = "[2;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .Ins } } },
    .{ .seq = "[3;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .Del } } },
    .{ .seq = "[5;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .PgUp } } },
    .{ .seq = "[6;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .PgDn } } },
    .{ .seq = "[1;7P", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F1 } } },
    .{ .seq = "[1;7Q", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F2 } } },
    .{ .seq = "[1;7R", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F3 } } },
    .{ .seq = "[1;7S", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F4 } } },
    .{ .seq = "[15;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F5 } } },
    .{ .seq = "[17;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F6 } } },
    .{ .seq = "[18;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F7 } } },
    .{ .seq = "[19;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F8 } } },
    .{ .seq = "[20;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F9 } } },
    .{ .seq = "[21;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F10 } } },
    .{ .seq = "[23;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F11 } } },
    .{ .seq = "[24;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .F12 } } },
    .{ .seq = "[29;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .Apps } } },
    .{ .seq = "[34;7~", .key = .{ .keyboard = .{ .ctrl = true, .alt = true, .key = .Win } } },
};

const AsciiToKeyCode = [0x80]App.InputEvent{
    .{ .keyboard = .{ .ctrl = true, .shift = false, .alt = false, .key = .At } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .A } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .B } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .C } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .D } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .E } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .F } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .G } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .H } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .Tab } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .J } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .K } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .L } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .Enter } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .N } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .O } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .P } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .Q } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .R } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .S } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .T } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .U } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .V } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .W } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .X } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .Y } },
    .{ .keyboard = .{ .ctrl = true, .shift = true, .alt = false, .key = .Z } },
    .{ .keyboard = .{ .ctrl = true, .shift = false, .alt = false, .key = .OpenBracket } },
    .{ .keyboard = .{ .ctrl = true, .shift = false, .alt = false, .key = .Backslash } },
    .{ .keyboard = .{ .ctrl = true, .shift = false, .alt = false, .key = .CloseBracket } },
    .{ .keyboard = .{ .ctrl = true, .shift = false, .alt = false, .key = .Caret } },
    .{ .keyboard = .{ .ctrl = true, .shift = false, .alt = false, .key = .Underscore } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Space } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Exclamation } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .DoubleQuote } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Hash } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Dollar } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Percent } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Ambersand } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .SingleQuote } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .OpenParen } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .CloseParen } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Asterisk } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Add } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Comma } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Minus } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Dot } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .ForwardSlash } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Zero } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .One } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Two } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Three } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Four } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Five } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Six } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Seven } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Eight } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Nine } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Colon } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .SemiColon } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .LeftAngle } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Equal } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .RightAngle } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .QuestionMark } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .At } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .A } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .B } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .C } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .D } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .E } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .F } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .G } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .H } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .I } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .J } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .K } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .L } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .M } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .N } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .O } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .P } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .Q } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .R } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .S } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .T } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .U } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .V } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .W } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .X } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .Y } },
    .{ .keyboard = .{ .ctrl = false, .shift = true, .alt = false, .key = .Z } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .OpenBracket } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Backslash } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .CloseBracket } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Caret } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Underscore } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Backtick } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .A } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .B } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .C } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .D } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .E } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .F } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .G } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .H } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .I } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .J } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .K } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .L } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .M } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .N } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .O } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .P } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Q } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .R } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .S } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .T } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .U } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .V } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .W } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .X } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Y } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Z } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .OpenBrace } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Pipe } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .CloseBrace } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Tilde } },
    .{ .keyboard = .{ .ctrl = false, .shift = false, .alt = false, .key = .Esc } },
};
const VMIN = 9;
const VTIME = 17;

pub fn decodeMouse(data: []const u8, len: *usize) App.InputEvent {
    const cb = data[0];
    const cx = data[1];
    const cy = data[2];
    len.* = 3;

    return .{ .mouse = .{ .button = cb & 0b11, .x = cx - 32, .y = cy - 32 } };
}

//1B   5B 31 3B 32 43
//<esc>[1;2C
pub fn read(input: []const u8, output: *std.ArrayList(App.InputEvent)) !void {
    var idx: usize = 0;
    inputLoop: while (idx < input.len) : (idx += 1) {
        const val = input[idx];
        switch (val) {
            0x1b => {
                idx += 1;
                const availLength = input.len - idx;
                if (availLength >= 2 and std.mem.eql(u8, "[M", input[idx .. idx + 2])) {
                    idx += 2;
                    var len: usize = 0;
                    const mouseEv = decodeMouse(input[idx..], &len);
                    idx += len;
                    try output.append(mouseEv);
                } else {
                    for (escapeCodes) |ec| {
                        if (availLength >= ec.seq.len) {
                            if (std.mem.eql(
                                u8,
                                ec.seq,
                                input[idx .. idx + ec.seq.len],
                            )) {
                                try output.append(ec.key);
                                idx += ec.seq.len;
                                continue :inputLoop;
                            }
                        }
                    }

                    if (availLength > 0) {
                        if (input[idx] <= 0x7F) {
                            var key = AsciiToKeyCode[input[idx]];
                            key.keyboard.alt = true;
                            try output.append(key);
                        } else {
                            try output.append(AsciiToKeyCode[0x7F]);
                        }
                    }
                }
            },
            0...0x1a, 0x1c...0x7F => {
                try output.append(AsciiToKeyCode[val]);
            },
            else => {
                //unexpected value
            },
        }
    }
}

pub const TerminalIO = struct {
    alloc: std.mem.Allocator,
    tc: std.os.termios,
    inputQueue: *std.ArrayList(App.InputEvent),
    outwriter: std.fs.File.Writer,
    const infd = std.os.STDIN_FILENO;
    const outfd = std.os.STDOUT_FILENO;
    pub fn init(
        alloc: std.mem.Allocator,
        inputQueue: *std.ArrayList(App.InputEvent),
    ) !*TerminalIO {
        var self = try alloc.create(TerminalIO);
        errdefer alloc.destroy(self);
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
        self.* = TerminalIO{
            .alloc = alloc,
            .tc = tc,
            .inputQueue = inputQueue,
            .outwriter = std.io.getStdOut().writer(),
        };
        return self;
    }
    pub fn deinit(self: *TerminalIO) void {
        _ = std.os.write(outfd, "\x1b[?1049l\x1b[?1002l") catch {};
        std.os.tcsetattr(infd, .FLUSH, self.tc) catch {};
        self.alloc.destroy(self);
    }
    pub fn addEventHandler(self: *TerminalIO, event: *ev.EventLoop) !void {
        try event.add(.{ .inFn = &infunc, .fd = infd, .ctx = self });
    }
    fn infunc(ctx: ?*anyopaque, event: *ev.EventLoop, fd: std.os.fd_t) ev.EventFnError!void {
        var self: *TerminalIO = @ptrCast(*TerminalIO, @alignCast(@alignOf(TerminalIO), ctx orelse return));
        var readBuf: [512]u8 = undefined;
        const len = std.os.read(fd, &readBuf) catch return;
        std.fmt.format(self.outwriter, "[{}]", .{std.fmt.fmtSliceHexUpper(readBuf[0..len])}) catch return;
        _ = event;
        read(readBuf[0..len], self.inputQueue) catch return;
    }
};
