const std = @import("std");

const r = @import("ray.zig");
const Ray3 = r.Ray3;
const util = @import("utils.zig");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;
const toVec = vec.toVec;

const hittable = @import("hittable.zig");

var image_width: usize = 950;
var image_height: usize = 600;
inline fn aspect_ratio() f32 {
    return util.toF32(usize, image_width) / util.toF32(usize, image_height);
}
var viewport_height: f32 = 2.0;
inline fn viewport_width() f32 {
    return viewport_height * aspect_ratio();
}
var focal_length: f32 = 2.0;

fn rayColor(ray: *const Ray3, world: *const hittable.HittableList) Color3 {
    const hit_record = world.hit(ray, 0, util.infinity);
    if (hit_record != null) {
        return toVec(0.5) * (hit_record.?.normal + Color3{ 1, 1, 1 });
    }
    const unit_direction = vec.unit(ray.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return toVec(1.0 - a) * Color3{ 1, 1, 1 } + toVec(a) * Color3{ 0.5, 0.7, 1 };
}

pub fn main() !void {
    // Setup stdout and stderr
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

    var s1 = hittable.Sphere.init(allocator, Point3{ 0, 0, -1 }, 0.2);
    var s2 = hittable.Sphere.init(allocator, Point3{ 0, -100.5, -1 }, 100);
    try world.add(&s1);
    try world.add(&s2);

    const camera_center: Point3 = .{ 0, 0, 0 };

    const viewport_u: Vec3 = .{ viewport_width(), 0, 0 };
    const viewport_v: Vec3 = .{ 0, -viewport_height, 0 };

    const pixel_delta_u = viewport_u / toVec(util.toF32(usize, image_width));
    const pixel_delta_v = viewport_v / toVec(util.toF32(usize, image_height));

    const viewport_upper_left = camera_center - Vec3{ 0, 0, focal_length } - (viewport_u / toVec(2)) - (viewport_v / toVec(2));
    const pixel00_loc = viewport_upper_left + (pixel_delta_u + pixel_delta_v * toVec(0.5));

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |row| {
        try util.writeProgressBar(row, image_height, 40, stderr);
        try bw_err.flush();
        for (0..image_width) |col| {
            const colf: f32 = util.toF32(usize, col);
            const rowf: f32 = util.toF32(usize, row);
            const pixel_center = pixel00_loc + (pixel_delta_u * toVec(colf)) + (pixel_delta_v * toVec(rowf));
            const ray_direction = pixel_center - camera_center;
            const ray = Ray3.new(camera_center, ray_direction);
            const pixel_color = rayColor(&ray, &world);
            try util.writeCol(pixel_color, stdout);
        }
    }

    try util.writeProgressBar(1, 1, 40, stderr);
    try stderr.writeByte('\n');

    try bw_err.flush();
    try bw.flush();
}

test {
    std.testing.refAllDecls(@This());
}
