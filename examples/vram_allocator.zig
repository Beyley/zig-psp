const sdk = @import("sdk");

var offset: sdk.c.SceSize = 0;

fn getMemorySize(width: sdk.c.SceSize, height: sdk.c.SceSize, comptime pixel_format: sdk.c.SceSize) sdk.c.SceSize {
    return switch (pixel_format) {
        sdk.c.GU_PSM_T4 => (width * height) >> 1,
        sdk.c.GU_PSM_T8 => width * height,
        sdk.c.GU_PSM_5650, sdk.c.GU_PSM_5551, sdk.c.GU_PSM_4444, sdk.c.GU_PSM_T16 => 2 * width * height,
        sdk.c.GU_PSM_8888, sdk.c.GU_PSM_T32 => 4 * width * height,
        else => @compileError("Unknown pixel format"),
    };
}

pub fn getStaticVramBuffer(width: sdk.c.SceSize, height: sdk.c.SceSize, comptime pixel_format: sdk.c.SceSize) ?*anyopaque {
    const memory_size = getMemorySize(width, height, pixel_format);

    var result: ?*anyopaque = @ptrFromInt(offset);
    offset += memory_size;

    return result;
}

pub fn getStaticVramTexture(width: sdk.c.SceSize, height: sdk.c.SceSize, comptime pixel_format: sdk.c.SceSize) ?*anyopaque {
    var result = getStaticVramBuffer(width, height, pixel_format);

    const ge_edram_addr = sdk.c.sceGeEdramGetAddr();

    return @ptrFromInt(@intFromPtr(result) + @intFromPtr(ge_edram_addr));
}
