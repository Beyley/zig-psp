const c = @import("sdk.zig").c;

var requested_exit: bool = false;

//Check if exit is requested
pub fn isRunning() bool {
    return !requested_exit;
}

//Exit
export fn exitCallback(arg1: c_int, arg2: c_int, common: ?*anyopaque) c_int {
    _ = arg1;
    _ = arg2;
    _ = common;

    requested_exit = true;
    c.sceKernelExitGame();
    return 0;
}

//Thread for home button exit thread.
export fn callbackThread(args: c.SceSize, argp: ?*anyopaque) c_int {
    _ = args;
    _ = argp;

    var callbackId = c.sceKernelCreateCallback("zig_exit_callback", exitCallback, null);
    var status = c.sceKernelRegisterExitCallback(callbackId);

    if (status < 0) {
        @panic("Could not setup a home button callback!");
    }

    status = c.sceKernelSleepThreadCB();

    return 0;
}

//This enables the home button exit callback above
pub fn enableHomeButtonCallback() !void {
    var threadID: i32 = c.sceKernelCreateThread("zig_callback_updater", callbackThread, 0x11, 0xFA0, c.PSP_THREAD_ATTR_USER, null);

    if (threadID < 0) {
        return error.UnableToCreateCallbackThread;
    }

    _ = c.sceKernelStartThread(threadID, 0, null);
}
