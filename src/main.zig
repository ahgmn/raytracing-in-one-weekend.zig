const std = @import("std");

const hittable = @import("hittable.zig");
const ih = @import("io_helpers.zig");
const mh = @import("math_helpers.zig");
const Ray = @import("ray.zig").Ray;
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;
const toVec = vec.toVec;

const image_width: usize = 950;
const image_height: usize = 600;
const aspect_ratio: f32 = mh.toF32(usize, image_width) / mh.toF32(usize, image_height);
const viewport_height: f32 = 2.0;
const viewport_width: f32 = viewport_height * aspect_ratio;
const focal_length: f32 = 2.0;

fn rayColor(ray: *const Ray, world: *const hittable.HittableList) Color3 {
    const hit_record = world.hit(ray, 0, mh.infinity);
    if (hit_record) |rec| {
        return toVec(0.5) * (rec.normal + Color3{ 1, 1, 1 });
    }
    const unit_direction = vec.unit(ray.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return toVec(1.0 - a) * Color3{ 1, 1, 1 } + toVec(a) * Color3{ 0.5, 0.7, 1 };
}

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

    const camera_center: Point3 = .{ 0, 0, 0 };

    const viewport_u: Vec3 = .{ viewport_width, 0, 0 };
    const viewport_v: Vec3 = .{ 0, -viewport_height, 0 };

    const pixel_delta_u = viewport_u / toVec(mh.toF32(usize, image_width));
    const pixel_delta_v = viewport_v / toVec(mh.toF32(usize, image_height));

    const viewport_upper_left = camera_center - Vec3{ 0, 0, focal_length } - (viewport_u / toVec(2)) - (viewport_v / toVec(2));
    const pixel00_loc = viewport_upper_left + (pixel_delta_u + pixel_delta_v * toVec(0.5));

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |row| {
        try ih.writeProgressBar(row, image_height, 40, stderr);
        try bw_err.flush();
        for (0..image_width) |col| {
            const colf: f32 = mh.toF32(usize, col);
            const rowf: f32 = mh.toF32(usize, row);
            const pixel_center = pixel00_loc + (pixel_delta_u * toVec(colf)) + (pixel_delta_v * toVec(rowf));
            const ray_direction = pixel_center - camera_center;
            const ray = Ray.new(camera_center, ray_direction);
            const pixel_color = rayColor(&ray, &world);
            try ih.writeCol(pixel_color, stdout);
        }
    }

    try ih.writeProgressBar(1, 1, 40, stderr);
    try stderr.writeByte('\n');

    try bw_err.flush();
    try bw.flush();
}

test {
    std.testing.refAllDecls(@This());
}
