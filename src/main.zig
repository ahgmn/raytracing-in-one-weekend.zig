const std = @import("std");

const util = @import("utils.zig");
const Vector = @import("vector.zig");
const Vec3f = Vector.Vec3f;
const Col3f = Vector.Col3f;

const image_width = 800;
const image_height = 600;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const stderr_file = std.io.getStdErr().writer();
    var bw_err = std.io.bufferedWriter(stderr_file);
    const stderr = bw_err.writer();

    // try stdout.print("{}", .{c});
    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |row| {
        try stderr.print("\nScalines remaining: {}", .{image_height - row});
        try bw_err.flush();
        for (0..image_width) |col| {
            const c = Col3f.new(util.to_f32(usize, row) / util.to_f32(usize, image_height), util.to_f32(usize, col) / util.to_f32(usize, image_width), 0.0);
            try util.write_col_to(c, stdout);
        }
    }

    try bw.flush(); // Don't forget to flush!
}
