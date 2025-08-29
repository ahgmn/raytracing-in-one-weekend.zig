const std = @import("std");

const Camera = @import("Camera.zig");
const hittable = @import("hittable.zig");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;

const image_width: usize = 950;
const aspect_ratio: f32 = 16.0 / 9.0;

pub fn main() !void {
    // Printing
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const stderr_file = std.io.getStdErr().writer();
    var bw_err = std.io.bufferedWriter(stderr_file);
    const stderr = bw_err.writer();
    // -----------------------
    // Allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // -----------------------
    // World
    var world = hittable.List.init(allocator);
    defer world.deinit(allocator);
    try world.add(try hittable.Sphere.init(allocator, Point3{ 0, 0, -1 }, 0.2));
    try world.add(try hittable.Sphere.init(allocator, Point3{ 0, -100.5, -1 }, 100));
    // -----------------------
    const camera = Camera.init(image_width, aspect_ratio);

    try camera.render(&world, stdout, stderr);

    try bw_err.flush();
    try bw.flush();
}

test {
    std.testing.refAllDecls(@This());
}
