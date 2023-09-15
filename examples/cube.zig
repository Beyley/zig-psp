const std = @import("std");

const sdk = @import("sdk");

const shared = @import("render_shared.zig");

const c = sdk.c;

comptime {
    asm (sdk.module.module_info("Zig PSP App", 0, 1, 0));
}

const Vertex = extern struct {
    u: f32,
    v: f32,
    color: u32,
    x: f32,
    y: f32,
    z: f32,
};

// zig fmt: off
const vertices: [12 * 3]Vertex = .{
    Vertex{.u = 0, .v = 0, .color = 0xff7f0000, .x = -1, .y = -1, .z =  1}, // 0
    Vertex{.u = 1, .v = 0, .color = 0xff7f0000, .x = -1, .y =  1, .z =  1}, // 4
    Vertex{.u = 1, .v = 1, .color = 0xff7f0000, .x =  1, .y =  1, .z =  1}, // 5

    Vertex{.u = 0, .v = 0, .color = 0xff7f0000, .x = -1, .y = -1, .z =  1}, // 0
    Vertex{.u = 1, .v = 1, .color = 0xff7f0000, .x =  1, .y =  1, .z =  1}, // 5
    Vertex{.u = 0, .v = 1, .color = 0xff7f0000, .x =  1, .y = -1, .z =  1}, // 1
    
    Vertex{.u = 0, .v = 0, .color = 0xff7f0000, .x = -1, .y = -1, .z = -1}, // 3
    Vertex{.u = 1, .v = 0, .color = 0xff7f0000, .x =  1, .y = -1, .z = -1}, // 2
    Vertex{.u = 1, .v = 1, .color = 0xff7f0000, .x =  1, .y =  1, .z = -1}, // 6
    
    Vertex{.u = 0, .v = 0, .color = 0xff7f0000, .x = -1, .y = -1, .z = -1}, // 3
    Vertex{.u = 1, .v = 1, .color = 0xff7f0000, .x =  1, .y =  1, .z = -1}, // 6
    Vertex{.u = 0, .v = 1, .color = 0xff7f0000, .x = -1, .y =  1, .z = -1}, // 7
    
    Vertex{.u = 0, .v = 0, .color = 0xff007f00, .x =  1, .y = -1, .z = -1}, // 0
    Vertex{.u = 1, .v = 0, .color = 0xff007f00, .x =  1, .y = -1, .z =  1}, // 3
    Vertex{.u = 1, .v = 1, .color = 0xff007f00, .x =  1, .y =  1, .z =  1}, // 7
    
    Vertex{.u = 0, .v = 0, .color = 0xff007f00, .x =  1, .y = -1, .z = -1}, // 0
    Vertex{.u = 1, .v = 1, .color = 0xff007f00, .x =  1, .y =  1, .z =  1}, // 7
    Vertex{.u = 0, .v = 1, .color = 0xff007f00, .x =  1, .y =  1, .z = -1}, // 4
    
    Vertex{.u = 0, .v = 0, .color = 0xff007f00, .x = -1, .y = -1, .z = -1}, // 0
    Vertex{.u = 1, .v = 0, .color = 0xff007f00, .x = -1, .y =  1, .z = -1}, // 3
    Vertex{.u = 1, .v = 1, .color = 0xff007f00, .x = -1, .y =  1, .z =  1}, // 7
    
    Vertex{.u = 0, .v = 0, .color = 0xff007f00, .x = -1, .y = -1, .z = -1}, // 0
    Vertex{.u = 1, .v = 1, .color = 0xff007f00, .x = -1, .y =  1, .z =  1}, // 7
    Vertex{.u = 0, .v = 1, .color = 0xff007f00, .x = -1, .y = -1, .z =  1}, // 4
    
    Vertex{.u = 0, .v = 0, .color = 0xff00007f, .x = -1, .y =  1, .z = -1}, // 0
    Vertex{.u = 1, .v = 0, .color = 0xff00007f, .x =  1, .y =  1, .z = -1}, // 1
    Vertex{.u = 1, .v = 1, .color = 0xff00007f, .x =  1, .y =  1, .z =  1}, // 2
    
    Vertex{.u = 0, .v = 0, .color = 0xff00007f, .x = -1, .y =  1, .z = -1}, // 0
    Vertex{.u = 1, .v = 1, .color = 0xff00007f, .x =  1, .y =  1, .z =  1}, // 2
    Vertex{.u = 0, .v = 1, .color = 0xff00007f, .x = -1, .y =  1, .z =  1}, // 3
    
    Vertex{.u = 0, .v = 0, .color = 0xff00007f, .x = -1, .y = -1, .z = -1}, // 4
    Vertex{.u = 1, .v = 0, .color = 0xff00007f, .x = -1, .y = -1, .z =  1}, // 7
    Vertex{.u = 1, .v = 1, .color = 0xff00007f, .x =  1, .y = -1, .z =  1}, // 6
    
    Vertex{.u = 0, .v = 0, .color = 0xff00007f, .x = -1, .y = -1, .z = -1}, // 4
    Vertex{.u = 1, .v = 1, .color = 0xff00007f, .x =  1, .y = -1, .z =  1}, // 6
    Vertex{.u = 0, .v = 1, .color = 0xff00007f, .x =  1, .y = -1, .z = -1}, // 5
};
// zig fmt: on

var list: [0x40000]c_uint align(16) = [1]c_uint{0} ** 0x40000;

const logo = @embedFile("logo.raw");

const BUF_WIDTH = 512;
const SCR_WIDTH = 480;
const SCR_HEIGHT = 272;

pub fn main() !void {
    try sdk.utils.enableHomeButtonCallback();

    // sdk.debug.screenInit();
    // sdk.debug.print("Hello from Zig!");

    var fbp0 = shared.vram.getStaticVramBuffer(BUF_WIDTH, SCR_HEIGHT, c.GU_PSM_8888);
    var fbp1 = shared.vram.getStaticVramBuffer(BUF_WIDTH, SCR_HEIGHT, c.GU_PSM_8888);
    var zbp = shared.vram.getStaticVramBuffer(BUF_WIDTH, SCR_HEIGHT, c.GU_PSM_4444);

    c.sceGuInit();
    defer c.sceGuTerm();

    c.sceGuStart(c.GU_DIRECT, &list);
    c.sceGuDrawBuffer(c.GU_PSM_8888, fbp0, BUF_WIDTH);
    c.sceGuDispBuffer(SCR_WIDTH, SCR_HEIGHT, fbp1, BUF_WIDTH);
    c.sceGuDepthBuffer(zbp, BUF_WIDTH);
    c.sceGuOffset(2048 - (SCR_WIDTH / 2), 2048 - (SCR_HEIGHT / 2));
    c.sceGuViewport(2048, 2048, SCR_WIDTH, SCR_HEIGHT);
    c.sceGuDepthRange(65535, 0);
    c.sceGuScissor(0, 0, SCR_WIDTH, SCR_HEIGHT);
    c.sceGuEnable(c.GU_SCISSOR_TEST);
    c.sceGuDepthFunc(c.GU_GEQUAL);
    c.sceGuEnable(c.GU_DEPTH_TEST);
    c.sceGuFrontFace(c.GU_CW);
    c.sceGuShadeModel(c.GU_SMOOTH);
    c.sceGuEnable(c.GU_CULL_FACE);
    c.sceGuEnable(c.GU_TEXTURE_2D);
    c.sceGuEnable(c.GU_CLIP_PLANES);
    _ = c.sceGuFinish();
    _ = c.sceGuSync(0, 0);

    _ = c.sceDisplayWaitVblankStart();
    _ = c.sceGuDisplay(c.GU_TRUE);

    // run sample

    var val: f32 = 0;

    while (sdk.utils.isRunning()) {
        c.sceGuStart(c.GU_DIRECT, &list);

        // clear screen

        c.sceGuClearColor(0xff554433);
        c.sceGuClearDepth(0);
        c.sceGuClear(c.GU_COLOR_BUFFER_BIT | c.GU_DEPTH_BUFFER_BIT);

        // setup matrices for cube

        c.sceGumMatrixMode(c.GU_PROJECTION);
        c.sceGumLoadIdentity();
        c.sceGumPerspective(75.0, 16.0 / 9.0, 0.5, 1000.0);

        c.sceGumMatrixMode(c.GU_VIEW);
        c.sceGumLoadIdentity();

        c.sceGumMatrixMode(c.GU_MODEL);
        c.sceGumLoadIdentity();
        {
            c.sceGumTranslate(&c.ScePspFVector3{ .x = 0, .y = 0, .z = -2.5 });
            c.sceGumRotateXYZ(&c.ScePspFVector3{
                .x = val * 0.79 * (c.GU_PI / 180.0),
                .y = val * 0.98 * (c.GU_PI / 180.0),
                .z = val * 1.32 * (c.GU_PI / 180.0),
            });
        }

        // setup texture

        c.sceGuTexMode(c.GU_PSM_4444, 0, 0, 0);
        c.sceGuTexImage(0, 64, 64, 64, logo.ptr);
        c.sceGuTexFunc(c.GU_TFX_ADD, c.GU_TCC_RGB);
        c.sceGuTexEnvColor(0xffff00);
        c.sceGuTexFilter(c.GU_LINEAR, c.GU_LINEAR);
        c.sceGuTexScale(1.0, 1.0);
        c.sceGuTexOffset(0.0, 0.0);
        c.sceGuAmbientColor(0xffffffff);

        // draw cube

        c.sceGumDrawArray(c.GU_TRIANGLES, c.GU_TEXTURE_32BITF | c.GU_COLOR_8888 | c.GU_VERTEX_32BITF | c.GU_TRANSFORM_3D, vertices.len, null, &vertices);

        _ = c.sceGuFinish();
        _ = c.sceGuSync(0, 0);

        _ = c.sceDisplayWaitVblankStart();
        _ = c.sceGuSwapBuffers();

        val += 1;
    }
}
