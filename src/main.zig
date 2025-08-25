const std = @import("std");
const Vector = @import("vector.zig");
const util = @import("utils.zig");

const Vec2 = Vector.Vec(2, f32);

const image_width = 800;
const image_height = 600;

pub fn main() !void {
    // const a = Vec2.init([_]f32{ 1, 2 });
    // const b = Vec2.init([_]f32{ 1, 2 });
    // const c = Vec2.add(a, b);
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const stderr_file = std.io.getStdErr().writer();
    var bw_err = std.io.bufferedWriter(stderr_file);
    const stderr = bw_err.writer();

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |row| {
        try stderr.print("\nScalines remaining: {}", .{image_height - row});
        try bw_err.flush();
        for (0..image_width) |col| {
            const r: u8 = util.clamp_to_u8(f32, util.to_f32(usize, row) / util.to_f32(usize, image_height));
            const g: u8 = util.clamp_to_u8(f32, util.to_f32(usize, col) / util.to_f32(usize, image_width));
            const b: u8 = 0;
            try stdout.print("{} {} {}\n", .{ r, g, b });
        }
    }

    try bw.flush(); // Don't forget to flush!
}
