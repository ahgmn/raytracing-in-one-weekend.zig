const std = @import("std");
const assert = std.debug.assert;

const Camera = @import("Camera.zig");
const hittable = @import("hittable.zig");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;

const image_width: usize = 950;
const aspect_ratio: f32 = 16.0 / 9.0;
const samples_per_pixel = 100;

pub fn main() !void {
    // Allocation
    // -----------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // -----------------------
    // Printing
    // -----------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;
    // -----------------------
    // File
    // -----------------------
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        try stdout.print("Usage: {s} <relative-path>\n", .{args[0]});
        try stdout.flush();
        return;
    }
    var file = try std.fs.cwd().createFile(args[1], .{
        .truncate = true,
        .read = false,
    });
    defer file.close();
    var file_buffer: [1024]u8 = undefined;
    var file_writer = file.writer(&file_buffer);
    const f = &file_writer.interface;
    // -----------------------
    // Random
    // -----------------------
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    // -----------------------
    // World
    // -----------------------
    var world = try hittable.List.init(allocator);
    defer world.deinit(allocator);
    try world.add(allocator, try hittable.Sphere.init(allocator, Point3{ 0, 0, -1 }, 0.2));
    try world.add(allocator, try hittable.Sphere.init(allocator, Point3{ 0, -100.5, -1 }, 100));
    // -----------------------
    const camera = Camera.init(image_width, aspect_ratio, samples_per_pixel);

    try camera.render(&world, rand, f, stdout);

    try stderr.flush();
    try stdout.flush();
}

test {
    std.testing.refAllDecls(@This());
}
