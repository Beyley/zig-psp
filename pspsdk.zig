const std = @import("std");

const Self = @This();

psp_sdk: []const u8,
pbp: *std.build.Step.Compile,
prx: *std.build.Step.Compile,
sfo: *std.Build.Step.Compile,

fn findPspSdk(b: *std.Build) ![]const u8 {
    var process = std.ChildProcess.init(&.{ "psp-config", "--pspsdk-path" }, b.allocator);
    process.stdout_behavior = .Pipe;
    process.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(b.allocator);
    var stderr = std.ArrayList(u8).init(b.allocator);
    defer stderr.deinit();

    try process.spawn();
    try process.collectOutput(&stdout, &stderr, std.fs.MAX_PATH_BYTES);
    _ = try process.wait();

    return std.mem.trim(u8, try stdout.toOwnedSlice(), " \r\n\t");
}

pub fn init(b: *std.Build) !Self {
    var pbp = b.addExecutable(.{
        .name = "pbptool",
        .root_source_file = .{ .path = "pbp/src/main.zig" },
    });
    var prx = b.addExecutable(.{
        .name = "prxgen",
        .link_libc = true,
    });
    prx.addCSourceFile(.{
        .file = .{ .path = "prxgen/psp-prxgen.c" },
        .flags = &.{ "-std=c99", "-Wno-address-of-packed-member", "-D_CRT_SECURE_NO_WARNINGS" },
    });
    var sfo = b.addExecutable(.{
        .name = "sfotool",
        .root_source_file = .{ .path = "sfo/src/main.zig" },
    });

    return .{
        .psp_sdk = try findPspSdk(b),
        .pbp = pbp,
        .prx = prx,
        .sfo = sfo,
    };
}

pub fn addExecutable(self: Self, b: *std.Build, options: std.build.ExecutableOptions) !*std.build.Step.Compile {
    var feature_set: std.Target.Cpu.Feature.Set = std.Target.Cpu.Feature.Set.empty;
    feature_set.addFeature(@intFromEnum(std.Target.mips.Feature.single_float));

    const target = std.zig.CrossTarget{ .cpu_arch = .mipsel, .os_tag = .freestanding, .cpu_model = .{ .explicit = &std.Target.mips.cpu.mips2 }, .cpu_features_add = feature_set };

    var zpsp = b.addStaticLibrary(.{
        .name = "zpsp",
        .target = target,
        .optimize = options.optimize,
        .root_source_file = .{ .path = "libzpsp/libzpsp.zig" },
    });

    var real_options = options;
    real_options.target = target;

    var exe = b.addExecutable(real_options);
    exe.setLinkerScript(.{ .path = "linkfile.ld" });
    exe.link_eh_frame_hdr = true;
    exe.link_emit_relocs = true;
    exe.single_threaded = true;
    exe.linkLibrary(zpsp);

    exe.addModule("sdk", b.createModule(.{
        .source_file = .{ .path = "sdk/sdk.zig" },
    }));

    // var libcFile = try self.createLibCFile(b);
    // exe.setLibCFile(libcFile);
    // libcFile.addStepDependencies(&exe.step);
    // exe.linkLibC();

    exe.addIncludePath(.{ .path = try std.fs.path.join(b.allocator, &.{ self.psp_sdk, "include/" }) });

    // exe.addLibraryPath(.{ .path = try std.fs.path.join(b.allocator, &.{ self.psp_sdk, "lib/" }) });
    // exe.linkSystemLibrary("pspkernel");

    return exe;
}

fn createLibCFile(self: Self, b: *std.Build) !std.build.FileSource {
    const fname = "psplibc.conf";

    var contents = std.ArrayList(u8).init(b.allocator);
    errdefer contents.deinit();

    var writer = contents.writer();

    const include_dir = try std.fs.path.join(b.allocator, &.{ self.psp_sdk, "include/" });

    //  The directory that contains `stdlib.h`.
    //  On POSIX-like systems, include directories be found with: `cc -E -Wp,-v -xc /dev/null
    try writer.print("include_dir={s}\n", .{include_dir});

    // The system-specific include directory. May be the same as `include_dir`.
    // On Windows it's the directory that includes `vcruntime.h`.
    // On POSIX it's the directory that includes `sys/errno.h`.
    try writer.print("sys_include_dir={s}\n", .{include_dir});

    try writer.print("crt_dir={s}\n", .{"/home/beyley/pspdev/psp/lib/"});
    try writer.writeAll("msvc_lib_dir=\n");
    try writer.writeAll("kernel32_lib_dir=\n");
    try writer.writeAll("gcc_dir=\n");

    // libc: /home/beyley/pspdev/bin/../lib/gcc/psp/11.2.0/../../../../psp/lib/libc.a

    const step = b.addWriteFiles();

    return step.add(fname, contents.items);
}

pub const BuildInfo = struct {
    title: []const u8,
    icon0: ?std.build.LazyPath = null,
    icon1: ?std.build.LazyPath = null,
    pic0: ?std.build.LazyPath = null,
    pic1: ?std.build.LazyPath = null,
    snd0: ?std.build.LazyPath = null,
};

pub fn createPbp(self: Self, b: *std.Build, exe: *std.Build.Step.Compile, build_info: BuildInfo) !std.build.LazyPath {
    //Make PRX file
    var build_prx = b.addRunArtifact(self.prx);
    build_prx.step.dependOn(&exe.step);

    build_prx.addFileArg(exe.getEmittedBin());
    const prx = build_prx.addOutputFileArg("app.prx");

    //Make SFO file
    var make_sfo = b.addSystemCommand(&.{"mksfoex"});

    make_sfo.addArgs(&.{build_info.title});
    const sfo = make_sfo.addOutputFileArg("PARAM.SFO");

    //Make final PBP file
    var pack_pbp = b.addRunArtifact(self.pbp);
    pack_pbp.step.dependOn(&make_sfo.step);
    pack_pbp.step.dependOn(&build_prx.step);

    pack_pbp.addArg("pack");
    var pbp = pack_pbp.addOutputFileArg("EBOOT.PBP");
    pack_pbp.addFileArg(sfo);
    if (build_info.icon0) |icon0| {
        pack_pbp.addFileArg(icon0);
    } else pack_pbp.addArg("NULL");
    if (build_info.icon1) |icon1| {
        pack_pbp.addFileArg(icon1);
    } else pack_pbp.addArg("NULL");
    if (build_info.pic0) |pic0| {
        pack_pbp.addFileArg(pic0);
    } else pack_pbp.addArg("NULL");
    if (build_info.pic1) |pic1| {
        pack_pbp.addFileArg(pic1);
    } else pack_pbp.addArg("NULL");
    if (build_info.snd0) |snd0| {
        pack_pbp.addFileArg(snd0);
    } else pack_pbp.addArg("NULL");
    pack_pbp.addFileArg(prx);
    pack_pbp.addArg("NULL");

    return pbp;
}
