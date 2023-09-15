const std = @import("std");
const pspsdk = @import("pspsdk.zig");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const sdk = try pspsdk.init(b);

    const exe = try sdk.addExecutable(b, .{
        .name = "test",
        .root_source_file = .{ .path = "example/main.zig" },
        .optimize = .ReleaseFast,
    });

    var pbp = try sdk.createPbp(b, exe, .{
        .title = "FUCK00000",
    });

    var install = b.addInstallBinFile(pbp, "EBOOT.PBP");
    b.getInstallStep().dependOn(&install.step);
}
