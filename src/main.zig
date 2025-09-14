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
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;
    // -----------------------
    // Allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // -----------------------
    // World
    var world = try hittable.List.init(allocator);
    defer world.deinit(allocator);
    try world.add(allocator, try hittable.Sphere.init(allocator, Point3{ 0, 0, -1 }, 0.2));
    try world.add(allocator, try hittable.Sphere.init(allocator, Point3{ 0, -100.5, -1 }, 100));
    // -----------------------
    const camera = Camera.init(image_width, aspect_ratio);

    try camera.render(&world, stdout, stderr);

    try stderr.flush();
    try stdout.flush();
}

test {
    std.testing.refAllDecls(@This());
}
