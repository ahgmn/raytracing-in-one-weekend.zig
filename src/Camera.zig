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
aspect_ratio: f64,
samples_per_pixel: usize,
pixel_samples_scale: f64,
max_depth: usize,

pub fn render(
    self: *const @This(),
    world: *const hittable.List,
    rand: std.Random,
    image_writer: *std.Io.Writer,
    progress_writer: *std.Io.Writer,
) !void {
    try image_writer.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

    for (0..self.image_height) |row| {
        try ih.writeProgressBar(row + 1, self.image_height, 40, progress_writer);
        for (0..self.image_width) |col| {
            var pixel_color = Color3{ 0, 0, 0 };
            for (0..self.samples_per_pixel) |_| {
                const r = getRay(self, col, row, rand);
                pixel_color += rayColor(&r, self.max_depth, world, rand);
            }
            try ih.writeColor(vec.from(self.pixel_samples_scale) * pixel_color, image_writer);
        }
    }
    try progress_writer.writeByte('\n');
}
pub fn init(
    image_width: usize,
    aspect_ratio: f64,
    samples_per_pixel: u32,
    max_depth: usize,
) @This() {
    const image_height = @as(usize, @intFromFloat(mh.toF64(usize, image_width) / aspect_ratio));

    const focal_length = 1.0;

    const viewport_height = 2.0;
    const viewport_width: f64 = viewport_height * mh.toF64(usize, image_width) / mh.toF64(usize, image_height);

    const camera_center: Point3 = .{ 0, 0, 0 };

    const viewport_u: Vec3 = .{ viewport_width, 0, 0 };
    const viewport_v: Vec3 = .{ 0, -viewport_height, 0 };

    const pixel_delta_u = viewport_u / vec.from(mh.toF64(usize, image_width));
    const pixel_delta_v = viewport_v / vec.from(mh.toF64(usize, image_height));

    const viewport_upper_left = camera_center - Vec3{ 0, 0, focal_length } - (viewport_u / vec.from(2)) - (viewport_v / vec.from(2));

    const pixel00_loc = viewport_upper_left + (pixel_delta_u + pixel_delta_v) * vec.from(0.5);

    const pixel_samples_scale = 1.0 / mh.toF64(usize, samples_per_pixel);

    return .{
        .image_width = image_width,
        .image_height = image_height,
        .center = camera_center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .aspect_ratio = aspect_ratio,
        .samples_per_pixel = samples_per_pixel,
        .pixel_samples_scale = pixel_samples_scale,
        .max_depth = max_depth,
    };
}

fn rayColor(ray: *const Ray, depth: usize, world: *const hittable.List, rand: std.Random) Color3 {
    if (depth <= 0) return Color3{ 0, 0, 0 };

    const hit_record = world.hit(ray, .{ .min = 0.001, .max = mh.infinity });
    if (hit_record) |rec| {
        const direction = rec.normal + vec.randomUnit(rand);
        return vec.from(0.5) * rayColor(&Ray.new(rec.p, direction), depth - 1, world, rand);
    }
    const unit_direction = vec.unit(ray.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return vec.from(1.0 - a) * Color3{ 1, 1, 1 } + vec.from(a) * Color3{ 0.5, 0.7, 1 };
}

inline fn getRay(self: *const @This(), col: usize, row: usize, rand: std.Random) Ray {
    const offset = sampleSquare(rand);
    const pixel_sample = self.pixel00_loc + vec.from(mh.toF64(usize, col) + offset[0]) * self.pixel_delta_u + vec.from(mh.toF64(usize, row) + offset[1]) * self.pixel_delta_v;
    const ray_origin = self.center;
    const ray_direction = pixel_sample - ray_origin;
    return Ray.new(ray_origin, ray_direction);
}

inline fn sampleSquare(rand: std.Random) Vec3 {
    return Vec3{ rand.float(f64) - 0.5, rand.float(f64) - 0.5, 0.0 };
}
