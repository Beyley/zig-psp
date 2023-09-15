const std = @import("std");
const io = std.io;
const mem = std.mem;
const process = std.process;
const fs = std.fs;

const common = @import("common.zig");

pub fn analyzePBP() !void {
    //Allocator setup
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    //Get args
    var arg_it = try process.argsWithAllocator(allocator);

    // Skip executable
    _ = arg_it.skip();
    // Skip command
    _ = arg_it.skip();

    //Get our input file - if it doesn't exist - error out
    var inputName = (arg_it.next() orelse {
        std.debug.print("Usage: pbptool analyze <input.pbp>\n\n", .{});
        return;
    });

    if (std.mem.eql(u8, inputName, "-h")) {
        std.debug.print("Usage: pbptool analyze <input.pbp>\n", .{});
        return;
    }

    //Open File
    var inFile = try fs.cwd().openFile(inputName, .{});
    defer inFile.close();

    //Get header
    var header = try common.readHeader(inFile);
    var size = try inFile.getEndPos();

    //Print entries
    std.debug.print("PBP Entry Table: \n", .{});

    var i: usize = 0;
    while (i < 8) : (i += 1) {
        var calcSize: usize = 0;

        if (i + 1 == 8) {
            calcSize = size - header.offset[7];
        } else {
            calcSize = header.offset[i + 1] - header.offset[i];
        }

        if (calcSize == 0) {
            std.debug.print("\t{s}: \tNOT PRESENT\n", .{common.default_file_names[i]});
        } else {
            std.debug.print("\t{s}: \tOFFSET {} \t SIZE {}\n", .{ common.default_file_names[i], header.offset[i], calcSize });
        }
    }
    std.debug.print("PBP Entry Table End\n\n", .{});

    //Read Version
    try inFile.seekTo(4);
    var ver_maj = try inFile.reader().readIntNative(u16);
    var ver_min = try inFile.reader().readIntNative(u16);

    //Finish Print
    std.debug.print("PBP Version: {d}.{d}\n", .{ ver_maj, ver_min });
    std.debug.print("Size: {d} bytes.\n", .{size});
}
