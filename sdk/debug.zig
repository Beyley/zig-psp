const c = @import("sdk.zig").c;

var x: u8 = 0;
var y: u8 = 0;
var vram_base: ?[*]u32 = null;

pub const SCREEN_WIDTH = 480;
pub const SCREEN_HEIGHT = 272;
pub const SCR_BUF_WIDTH = 512;

//Initialize the screen
pub fn screenInit() void {
    x = 0;
    y = 0;

    vram_base = @as(?[*]u32, @ptrFromInt(0x40000000 | @intFromPtr(c.sceGeEdramGetAddr())));

    _ = c.sceDisplaySetMode(0, SCREEN_WIDTH, SCREEN_HEIGHT);
    _ = c.sceDisplaySetFrameBuf(vram_base, SCR_BUF_WIDTH, c.PSP_DISPLAY_PIXEL_FORMAT_8888, 1);

    screenClear();
}

//Print out a constant string
pub fn print(text: []const u8) void {
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == '\n') {
            y += 1;
            x = 0;
        } else if (text[i] == '\t') {
            x += 4;
        } else {
            internal_putchar(@as(u32, x) * 8, @as(u32, y) * 8, text[i]);
            x += 1;
        }

        if (x > 60) {
            x = 0;
            y += 1;
            if (y > 34) {
                y = 0;
                screenClear();
            }
        }
    }
}

//Our font
pub const msxFont = @embedFile("./msxfont2.bin");

fn internal_putchar(cx: u32, cy: u32, ch: u8) void {
    var off: usize = cx + (cy * SCR_BUF_WIDTH);

    var i: usize = 0;
    while (i < 8) : (i += 1) {
        var j: usize = 0;

        while (j < 8) : (j += 1) {
            const mask: u32 = 128;

            var idx: u32 = @as(u32, ch - 32) * 8 + i;
            var glyph: u8 = msxFont[idx];

            if ((glyph & (mask >> @as(@import("std").math.Log2Int(c_int), @intCast(j)))) != 0) {
                vram_base.?[j + i * SCR_BUF_WIDTH + off] = fg_col;
            } else if (back_col_enable) {
                vram_base.?[j + i * SCR_BUF_WIDTH + off] = bg_col;
            }
        }
    }
}

var back_col_enable: bool = false;

//Clears the screen to the clear color (default is black)
pub fn screenClear() void {
    var i: usize = 0;
    while (i < SCR_BUF_WIDTH * SCREEN_HEIGHT) : (i += 1) {
        vram_base.?[i] = cl_col;
    }
}

//Color variables
var cl_col: u32 = 0xFF000000;
var bg_col: u32 = 0x00000000;
var fg_col: u32 = 0xFFFFFFFF;
