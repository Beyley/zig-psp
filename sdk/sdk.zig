pub const module = @import("module.zig");
pub const utils = @import("utils.zig");
pub const debug = @import("debug.zig");
pub const c = @cImport({
    @cInclude("pspkerneltypes.h");
    @cInclude("pspthreadman.h");
    @cInclude("psploadexec.h");
    @cInclude("pspdisplay.h");
    @cInclude("pspge.h");
    @cInclude("pspdebug.h");
});
