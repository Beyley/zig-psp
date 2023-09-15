const std = @import("std");
const pspsdk = @import("pspsdk.zig");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const sdk = try pspsdk.init(b);

    const exe = try sdk.addExecutable(b, .{
        .name = "cubetest",
        .root_source_file = .{ .path = "examples/cube.zig" },
        .optimize = .ReleaseFast,
    });

    var pbp = try sdk.createPbp(b, exe, .{
        .title = "Zig Cube Test",
    });

    var install = b.addInstallBinFile(pbp, "EBOOT.PBP");
    b.getInstallStep().dependOn(&install.step);

    var run_step = b.step("run", "run PPSSPP on the EBOOT");
    var run_ppsspp = b.addSystemCommand(&.{"PPSSPPSDL"});
    run_ppsspp.addFileArg(pbp);
    pbp.addStepDependencies(&run_ppsspp.step);
    run_step.dependOn(&run_ppsspp.step);
}
