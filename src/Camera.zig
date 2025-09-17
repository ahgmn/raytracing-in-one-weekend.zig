const hittable = @import("hittable.zig");
const std = @import("std");
const ih = @import("io_helpers.zig");
const mh = @import("math_helpers.zig");
const Ray = @import("Ray.zig");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;

image_width: usize,
image_height: usize,
center: Point3,
pixel00_loc: Point3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,
aspect_ratio: f32,

pub fn render(self: *const @This(), world: *const hittable.List, image_writer: *std.Io.Writer, progress_writer: *std.Io.Writer) !void {
    try image_writer.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

    for (0..self.image_height) |row| {
        try ih.writeProgressBar(row + 1, self.image_height, 40, progress_writer);
        for (0..self.image_width) |col| {
            const colf: f32 = mh.toF32(usize, col);
            const rowf: f32 = mh.toF32(usize, row);
            const pixel_center = self.pixel00_loc + (self.pixel_delta_u * vec.from(colf)) + (self.pixel_delta_v * vec.from(rowf));
            const ray_direction = pixel_center - self.center;
            const ray = Ray.new(self.center, ray_direction);
            const pixel_color = rayColor(&ray, world);
            try ih.writeCol(pixel_color, image_writer);
        }
    }
    try progress_writer.writeByte('\n');
}
pub fn init(image_width: usize, aspect_ratio: f32) @This() {
    const image_height = @as(usize, @intFromFloat(mh.toF32(usize, image_width) / aspect_ratio));

    const focal_length = 1.0;

    const viewport_height = 2.0;
    const viewport_width: f32 = viewport_height * aspect_ratio;

    const camera_center: Point3 = .{ 0, 0, 0 };

    const viewport_u: Vec3 = .{ viewport_width, 0, 0 };
    const viewport_v: Vec3 = .{ 0, -viewport_height, 0 };

    const pixel_delta_u = viewport_u / vec.from(mh.toF32(usize, image_width));
    const pixel_delta_v = viewport_v / vec.from(mh.toF32(usize, image_height));

    const viewport_upper_left = camera_center - Vec3{ 0, 0, focal_length } - (viewport_u / vec.from(2)) - (viewport_v / vec.from(2));

    const pixel00_loc = viewport_upper_left + (pixel_delta_u + pixel_delta_v * vec.from(0.5));

    return .{
        .image_width = image_width,
        .image_height = image_height,
        .center = camera_center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .aspect_ratio = aspect_ratio,
    };
}

fn rayColor(ray: *const Ray, world: *const hittable.List) Color3 {
    const hit_record = world.hit(ray, .{ .min = 0, .max = mh.infinity });
    if (hit_record) |rec| {
        return vec.from(0.5) * (rec.normal + Color3{ 1, 1, 1 });
    }
    const unit_direction = vec.unit(ray.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return vec.from(1.0 - a) * Color3{ 1, 1, 1 } + vec.from(a) * Color3{ 0.5, 0.7, 1 };
}
