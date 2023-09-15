const std = @import("std");

const sdk = @import("sdk");

comptime {
    asm (sdk.module.module_info("Zig PSP App", 0, 1, 0));
}

pub fn main() !void {
    sdk.utils.enableHBCB();
    sdk.debug.screenInit();

    sdk.debug.print("Hello from Zig!");
}
