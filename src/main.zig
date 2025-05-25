const zighash = @import("zighash_lib");
const std = @import("std");

pub fn main() !void {
    const hash = zighash.cityHash64("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    std.debug.print("{any}\n", .{hash});
}
