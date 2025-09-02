const std = @import("std");
const ssh = @cImport({
    @cInclude("libssh/libssh.h");
});

pub const SSHOpts = struct {
    host: [:0]const u8,
    username: ?[:0]const u8 = null,
    auth: union(enum) {
        key: [:0]const u8,
        password: [:0]const u8,
        auto: void,
    },
    port: ?c_int = null,
};

pub fn run(opts: SSHOpts) !void {
    const session = ssh.ssh_new() orelse return error.FailedToInit;

    defer ssh.ssh_free(session);

    const verbosity = ssh.SSH_LOG_PROTOCOL;

    _ = ssh.ssh_options_set(session, ssh.SSH_OPTIONS_HOST, @ptrCast(opts.host));
    _ = ssh.ssh_options_set(session, ssh.SSH_OPTIONS_LOG_VERBOSITY, @ptrCast(&verbosity));
    if (opts.port) |p| {
        _ = ssh.ssh_options_set(session, ssh.SSH_OPTIONS_PORT, @ptrCast(&p));
    }
    if (ssh.ssh_connect(session) != ssh.SSH_OK) {
        return error.FailedToConnect;
    }
    defer ssh.ssh_disconnect(session);
    switch (opts.auth) {
        .password => |p| _ = ssh.ssh_userauth_password(session, null, p),
        .key => |k| {
            _ = k;
        },
        .auto => {
            _ = ssh.ssh_userauth_publickey_auto(session, null, null);
        },
    }
    try show_remote_processes(session);
}

fn show_remote_processes(session: ssh.ssh_session) !void {
    const channel = ssh.ssh_channel_new(session);
    if (channel == null) {
        return error.SSH_ERROR;
    }
    defer ssh.ssh_channel_free(channel);
    if (ssh.ssh_channel_open_session(channel) != ssh.SSH_OK) {
        return error.openSessionFailed;
    }
    defer _ = ssh.ssh_channel_close(channel);

    if (ssh.ssh_channel_request_exec(channel, "ps aux") != ssh.SSH_OK) {
        return error.ExecFail;
    }
    var buffer: [4096]u8 = undefined;
    var nbytes = ssh.ssh_channel_read(channel, &buffer, buffer.len, 0);
    while (nbytes > 0) {
        std.log.info("Read:[{s}]", .{buffer[0..nbytes]});

        nbytes = ssh.ssh_channel_read(channel, &buffer, buffer.len, 0);
    }

    ssh.ssh_channel_send_eof(channel);
    ssh.ssh_channel_close(channel);
    ssh.ssh_channel_free(channel);

    return ssh.SSH_OK;
}
