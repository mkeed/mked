const std = @import("std");
const colour = @import("Colour.zig");
pub const FaceId = usize;

pub const Rect = struct {
    width: usize,
    height: usize,
};

pub const Symbol = struct {
    face: FaceId,
    text: []const u8,
};

pub const MenuLine = struct {
    items: []const Symbol,
};

pub const CommandLine = struct {
    items: []const Symbol,
};

const Line = struct {
    items: []const Symbol,
};

pub const View = struct {
    lines: []const Line,
    viewLine: []const Symbol,
};

pub const Screen = struct {
    menuLine: MenuLine,
    views: []const View,
    commandLine: CommandLine,
};

pub const ExampleScreen = Screen{
    .menuLine = MenuLine{
        .items = &.{
            .{ .face = 2, .text = "File" },
            .{ .face = 2, .text = "Edit" },
            .{ .face = 2, .text = "Options" },
            .{ .face = 2, .text = "Buffers" },
            .{ .face = 2, .text = "Tools" },
            .{ .face = 2, .text = "Help" },
        },
    },
    .views = &.{
        View{
            .lines = &.{
                .{ .items = &.{.{ .face = 1, .text = "pub const CommandLine = struct " }} },
                .{ .items = &.{.{ .face = 2, .text = "pub const CommandLine = struct " }} },
                .{ .items = &.{.{ .face = 3, .text = "pub const CommandLine = struct " }} },
                .{ .items = &.{.{ .face = 4, .text = "pub const CommandLine = struct " }} },
            },
            .viewLine = &.{.{ .face = 2, .text = "-UUU:@**--F8  App.zig        20% L61   Git:main  (Zig ARev) --------------------------------------------------------" }},
        },
    },
    .commandLine = .{ .items = &.{.{ .face = 1, .text = "C-x C-g is undefined" }} },
};

// |<----------------------------------------[window Vertical split]------------------------------>|
// |-----------------------------------------------------------------------------------------------|
// |  (menu_line)                                                                                  |
// |-----------------------------------------------------------------------------------------------|
// | (view)                                      | (view)                                          |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |-------------------------------------------------|
// |                                             |(mode_line)                                      |
// |                                             |-------------------------------------------------|
// |                                             |(view)                                           |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |                                             |                                                 |
// |-----------------------------------------------------------------------------------------------|
// |   (mode_line)                               | (mode_line)                                     |
// |-----------------------------------------------------------------------------------------------|
// |   (command_line)                                                                              |
// |-----------------------------------------------------------------------------------------------|
