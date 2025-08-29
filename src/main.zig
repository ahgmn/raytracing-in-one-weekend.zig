const std = @import("std");

const hittable = @import("hittable.zig");
const ih = @import("io_helpers.zig");
const mh = @import("math_helpers.zig");
const Ray = @import("ray.zig").Ray;
const vec = @import("vector.zig");
const Camera = @import("camera.zig").Camera;
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;
const toVec = vec.toVec;

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
    var world = hittable.HittableList.init(allocator);
    defer _ = world.deinit(allocator);
    try world.add(hittable.Sphere.init(allocator, Point3{ 0, 0, -1 }, 0.2));
    try world.add(hittable.Sphere.init(allocator, Point3{ 0, -100.5, -1 }, 100));
    // -----------------------

    const camera = Camera.init(image_width, aspect_ratio);
    try camera.render(&world, stdout, stderr);

    try bw_err.flush();
    try bw.flush();
}

test {
    std.testing.refAllDecls(@This());
}
