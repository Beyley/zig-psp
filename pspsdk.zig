const std = @import("std");

const Self = @This();

psp_sdk: []const u8,
psp_prefix: []const u8,
pbp: *std.build.Step.Compile,
prx: *std.build.Step.Compile,
sfo: *std.Build.Step.Compile,

fn findPspPrefix(b: *std.Build) ![]const u8 {
    var process = std.ChildProcess.init(&.{ "psp-config", "--psp-prefix" }, b.allocator);
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
        .psp_prefix = try findPspPrefix(b),
        .pbp = pbp,
        .prx = prx,
        .sfo = sfo,
    };
}

fn createGu(self: Self, b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) !*std.build.Step.Compile {
    var gu = b.addStaticLibrary(.{
        .name = "gu",
        .target = target,
        .optimize = optimize,
    });

    gu.addIncludePath(.{ .path = try std.fs.path.join(b.allocator, &.{ self.psp_prefix, "include/" }) });
    gu.addIncludePath(.{ .path = try std.fs.path.join(b.allocator, &.{ self.psp_sdk, "include/" }) });

    gu.addIncludePath(.{ .path = "pspsdk/src/base/" });
    gu.addIncludePath(.{ .path = "pspsdk/src/ge/" });
    gu.addIncludePath(.{ .path = "pspsdk/src/kernel/" });
    gu.addIncludePath(.{ .path = "pspsdk/src/display/" });
    gu.addIncludePath(.{ .path = "pspsdk/src/user/" });
    gu.addIncludePath(.{ .path = "pspsdk/src/debug/" });
    gu.addCSourceFiles(&.{
        "pspsdk/src/gu/callbackFin.c",
        "pspsdk/src/gu/callbackSig.c",
        "pspsdk/src/gu/guInternal.c",
        "pspsdk/src/gu/resetValues.c",
        "pspsdk/src/gu/sceGuAlphaFunc.c",
        "pspsdk/src/gu/sceGuAmbient.c",
        "pspsdk/src/gu/sceGuAmbientColor.c",
        "pspsdk/src/gu/sceGuBeginObject.c",
        "pspsdk/src/gu/sceGuBlendFunc.c",
        "pspsdk/src/gu/sceGuBoneMatrix.c",
        "pspsdk/src/gu/sceGuBreak.c",
        "pspsdk/src/gu/sceGuCallList.c",
        "pspsdk/src/gu/sceGuCallMode.c",
        "pspsdk/src/gu/sceGuCheckList.c",
        "pspsdk/src/gu/sceGuClear.c",
        "pspsdk/src/gu/sceGuClearColor.c",
        "pspsdk/src/gu/sceGuClearDepth.c",
        "pspsdk/src/gu/sceGuClearStencil.c",
        "pspsdk/src/gu/sceGuClutLoad.c",
        "pspsdk/src/gu/sceGuClutMode.c",
        "pspsdk/src/gu/sceGuColor.c",
        "pspsdk/src/gu/sceGuColorFunc.c",
        "pspsdk/src/gu/sceGuColorMaterial.c",
        "pspsdk/src/gu/sceGuContinue.c",
        "pspsdk/src/gu/sceGuCopyImage.c",
        "pspsdk/src/gu/sceGuDepthBuffer.c",
        "pspsdk/src/gu/sceGuDepthFunc.c",
        "pspsdk/src/gu/sceGuDepthMask.c",
        "pspsdk/src/gu/sceGuDepthOffset.c",
        "pspsdk/src/gu/sceGuDepthRange.c",
        "pspsdk/src/gu/sceGuDisable.c",
        "pspsdk/src/gu/sceGuDispBuffer.c",
        "pspsdk/src/gu/sceGuDisplay.c",
        "pspsdk/src/gu/sceGuDrawArray.c",
        "pspsdk/src/gu/sceGuDrawArrayN.c",
        "pspsdk/src/gu/sceGuDrawBezier.c",
        "pspsdk/src/gu/sceGuDrawBuffer.c",
        "pspsdk/src/gu/sceGuDrawBufferList.c",
        "pspsdk/src/gu/sceGuDrawSpline.c",
        "pspsdk/src/gu/sceGuEnable.c",
        "pspsdk/src/gu/sceGuEndObject.c",
        "pspsdk/src/gu/sceGuFinish.c",
        "pspsdk/src/gu/sceGuFog.c",
        "pspsdk/src/gu/sceGuFrontFace.c",
        "pspsdk/src/gu/sceGuGetAllStatus.c",
        "pspsdk/src/gu/sceGuGetMemory.c",
        "pspsdk/src/gu/sceGuGetStatus.c",
        "pspsdk/src/gu/sceGuInit.c",
        "pspsdk/src/gu/sceGuLight.c",
        "pspsdk/src/gu/sceGuLightAtt.c",
        "pspsdk/src/gu/sceGuLightColor.c",
        "pspsdk/src/gu/sceGuLightMode.c",
        "pspsdk/src/gu/sceGuLightSpot.c",
        "pspsdk/src/gu/sceGuLogicalOp.c",
        "pspsdk/src/gu/sceGuMaterial.c",
        "pspsdk/src/gu/sceGuModelColor.c",
        "pspsdk/src/gu/sceGuMorphWeight.c",
        "pspsdk/src/gu/sceGuOffset.c",
        "pspsdk/src/gu/sceGuPatchDivide.c",
        "pspsdk/src/gu/sceGuPatchFrontFace.c",
        "pspsdk/src/gu/sceGuPatchPrim.c",
        "pspsdk/src/gu/sceGuPixelMask.c",
        "pspsdk/src/gu/sceGuScissor.c",
        "pspsdk/src/gu/sceGuSendCommandf.c",
        "pspsdk/src/gu/sceGuSendCommandi.c",
        "pspsdk/src/gu/sceGuSendList.c",
        "pspsdk/src/gu/sceGuSetAllStatus.c",
        "pspsdk/src/gu/sceGuSetCallback.c",
        "pspsdk/src/gu/sceGuSetDither.c",
        "pspsdk/src/gu/sceGuSetMatrix.c",
        "pspsdk/src/gu/sceGuSetStatus.c",
        "pspsdk/src/gu/sceGuShadeModel.c",
        "pspsdk/src/gu/sceGuSignal.c",
        "pspsdk/src/gu/sceGuSpecular.c",
        "pspsdk/src/gu/sceGuStart.c",
        "pspsdk/src/gu/sceGuStencilFunc.c",
        "pspsdk/src/gu/sceGuStencilOp.c",
        "pspsdk/src/gu/sceGuSwapBuffers.c",
        "pspsdk/src/gu/sceGuSync.c",
        "pspsdk/src/gu/sceGuTerm.c",
        "pspsdk/src/gu/sceGuTexEnvColor.c",
        "pspsdk/src/gu/sceGuTexFilter.c",
        "pspsdk/src/gu/sceGuTexFlush.c",
        "pspsdk/src/gu/sceGuTexFunc.c",
        "pspsdk/src/gu/sceGuTexImage.c",
        "pspsdk/src/gu/sceGuTexLevelMode.c",
        "pspsdk/src/gu/sceGuTexMapMode.c",
        "pspsdk/src/gu/sceGuTexMode.c",
        "pspsdk/src/gu/sceGuTexOffset.c",
        "pspsdk/src/gu/sceGuTexProjMapMode.c",
        "pspsdk/src/gu/sceGuTexScale.c",
        "pspsdk/src/gu/sceGuTexSlope.c",
        "pspsdk/src/gu/sceGuTexSync.c",
        "pspsdk/src/gu/sceGuTexWrap.c",
        "pspsdk/src/gu/sceGuViewport.c",
        "pspsdk/src/gu/sendCommand.c",
    }, &.{ "-std=gnu99", "-Wno-address-of-packed-member", "-D_CRT_SECURE_NO_WARNINGS" });

    return gu;
}

fn createGum(self: Self, b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) !*std.build.Step.Compile {
    const shared_objects: []const []const u8 = &.{
        "gumLoadMatrix",
        "gumOrtho",
        "gumPerspective",
        "gumLookAt",
        "gumRotateXYZ",
        "gumRotateZYX",
        "gumFullInverse",
        "gumCrossProduct",
        "gumDotProduct",
        "gumNormalize",
        "sceGumDrawArray",
        "sceGumDrawArrayN",
        "sceGumDrawBezier",
        "sceGumDrawSpline",
        "sceGumRotateXYZ",
        "sceGumRotateZY",
    };

    const fpu_objects: []const []const u8 = &.{
        "sceGumLoadIdentity",
        "sceGumLoadMatrix",
        "sceGumMatrixMode",
        "sceGumMultMatrix",
        "sceGumOrtho",
        "sceGumPerspective",
        "sceGumPopMatrix",
        "sceGumPushMatrix",
        "sceGumScale",
        "sceGumTranslate",
        "sceGumUpdateMatrix",
        "sceGumStoreMatrix",
        "sceGumLookAt",
        "sceGumRotateX",
        "sceGumRotateY",
        "sceGumRotateZ",
        "sceGumFullInverse",
        "sceGumFastInverse",
        "sceGumBeginObject",
        "sceGumEndObject",
        "gumScale",
        "gumTranslate",
        "gumLoadIdentity",
        "gumFastInverse",
        "gumMultMatrix",
        "gumRotateX",
        "gumRotateY",
        "gumRotateZ",
        "gumIni",
    };

    var gum = b.addStaticLibrary(.{
        .name = "gum",
        .target = target,
        .optimize = optimize,
    });

    gum.addIncludePath(.{ .path = try std.fs.path.join(b.allocator, &.{ self.psp_prefix, "include/" }) });
    gum.addIncludePath(.{ .path = try std.fs.path.join(b.allocator, &.{ self.psp_sdk, "include/" }) });

    gum.addIncludePath(.{ .path = "pspsdk/src/base/" });
    gum.addIncludePath(.{ .path = "pspsdk/src/ge/" });
    gum.addIncludePath(.{ .path = "pspsdk/src/kernel/" });
    gum.addIncludePath(.{ .path = "pspsdk/src/display/" });
    gum.addIncludePath(.{ .path = "pspsdk/src/user/" });
    gum.addIncludePath(.{ .path = "pspsdk/src/vfpu/" });

    for (shared_objects) |shared_object| {
        gum.defineCMacro(b.fmt("F_{s}", .{shared_object}), "1");
    }

    for (fpu_objects) |fpu_object| {
        gum.defineCMacro(b.fmt("F_{s}", .{fpu_object}), "1");
    }

    const flags = &.{ "-std=gnu99", "-Wno-address-of-packed-member", "-D_CRT_SECURE_NO_WARNINGS" };

    gum.addCSourceFile(.{ .file = .{ .path = "pspsdk/src/gum/pspgum.c" }, .flags = flags });
    gum.addCSourceFile(.{ .file = .{ .path = "pspsdk/src/gum/gumInternal.c" }, .flags = flags });

    return gum;
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

    var gu = try self.createGu(b, target, options.optimize);
    var gum = try self.createGum(b, target, options.optimize);

    var exe = b.addExecutable(real_options);
    exe.setLinkerScript(.{ .path = "linkfile.ld" });
    exe.link_eh_frame_hdr = true;
    exe.link_emit_relocs = true;
    exe.single_threaded = true;
    exe.disable_sanitize_c = true;
    exe.linkLibrary(zpsp);
    exe.linkLibrary(gu);
    exe.linkLibrary(gum);

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

// fn createLibCFile(self: Self, b: *std.Build) !std.build.FileSource {
//     const fname = "psplibc.conf";

//     var contents = std.ArrayList(u8).init(b.allocator);
//     errdefer contents.deinit();

//     var writer = contents.writer();

//     const include_dir = try std.fs.path.join(b.allocator, &.{ self.psp_sdk, "include/" });

//     //  The directory that contains `stdlib.h`.
//     //  On POSIX-like systems, include directories be found with: `cc -E -Wp,-v -xc /dev/null
//     try writer.print("include_dir={s}\n", .{include_dir});

//     // The system-specific include directory. May be the same as `include_dir`.
//     // On Windows it's the directory that includes `vcruntime.h`.
//     // On POSIX it's the directory that includes `sys/errno.h`.
//     try writer.print("sys_include_dir={s}\n", .{include_dir});

//     try writer.print("crt_dir={s}\n", .{"/home/beyley/pspdev/psp/lib/"});
//     try writer.writeAll("msvc_lib_dir=\n");
//     try writer.writeAll("kernel32_lib_dir=\n");
//     try writer.writeAll("gcc_dir=\n");

//     // libc: /home/beyley/pspdev/bin/../lib/gcc/psp/11.2.0/../../../../psp/lib/libc.a

//     const step = b.addWriteFiles();

//     return step.add(fname, contents.items);
// }

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
