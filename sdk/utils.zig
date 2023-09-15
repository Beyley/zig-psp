const c = @import("sdk.zig").c;

var requestedExit: bool = false;

//Check if exit is requested
pub fn isRunning() bool {
    return requestedExit;
}

//Exit
export fn exitCB(arg1: c_int, arg2: c_int, common: ?*anyopaque) c_int {
    _ = arg1;
    _ = arg2;
    _ = common;
    requestedExit = true;
    c.sceKernelExitGame();
    return 0;
}

//Thread for home button exit thread.
export fn cbThread(args: c.SceSize, argp: ?*anyopaque) c_int {
    _ = args;
    _ = argp;

    var cbID: i32 = -1;

    cbID = c.sceKernelCreateCallback("zig_exit_callback", exitCB, null);
    var status = c.sceKernelRegisterExitCallback(cbID);

    if (status < 0) {
        @panic("Could not setup a home button callback!");
    }

    status = c.sceKernelSleepThreadCB();

    return 0;
}

//This enables the home button exit callback above
pub fn enableHBCB() void {
    var threadID: i32 = c.sceKernelCreateThread("zig_callback_updater", cbThread, 0x11, 0xFA0, c.PSP_THREAD_ATTR_USER, null);
    if (threadID >= 0) {
        _ = c.sceKernelStartThread(threadID, 0, null); //We don't know what stat does.
    } else {
        @panic("Could not setup a home button callback thread!");
    }
}
