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
    try image_writer.print(
        "P3\n{} {}\n255\n",
        .{ self.image_width, self.image_height },
    );

    for (0..self.image_height) |row| {
        for (0..self.image_width) |col| {
            var pixel_color = Color3{ 0, 0, 0 };
            for (0..self.samples_per_pixel) |_| {
                const r = getRay(self, col, row, rand);
                pixel_color += rayColor(&r, self.max_depth, world, rand);
            }
            try ih.writeColor(
                vec.from(self.pixel_samples_scale) * pixel_color,
                image_writer,
            );
        }
        try ih.writeProgressBar(row + 1, self.image_height, 40, progress_writer);
        try progress_writer.flush();
    }
    try progress_writer.writeByte('\n');
}
pub fn init(
    image_width: usize,
    aspect_ratio: f64,
    samples_per_pixel: u32,
    max_depth: usize,
) @This() {
    const image_width_f: f64 = @floatFromInt(image_width);
    const image_height: usize =
        @intFromFloat(@divTrunc(image_width_f, aspect_ratio));

    const focal_length = 1.0;

    const viewport_height = 2.0;
    const viewport_width: f64 = blk: {
        const image_height_f: f64 = @floatFromInt(image_height);
        const new_aspect_ratio = image_width_f / image_height_f;
        break :blk viewport_height * new_aspect_ratio;
    };

    const camera_center: Point3 = .{ 0, 0, 0 };

    const viewport_u: Vec3 = .{ viewport_width, 0, 0 };
    const viewport_v: Vec3 = .{ 0, -viewport_height, 0 };

    const pixel_delta_u = viewport_u / vec.from(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v / vec.from(@floatFromInt(image_height));

    const viewport_upper_left = blk: {
        const half_viewport_u = (viewport_u / vec.from(2));
        const half_viewport_v = (viewport_v / vec.from(2));
        const viewport_offset = half_viewport_u + half_viewport_v;
        break :blk camera_center - Vec3{ 0, 0, focal_length } - viewport_offset;
    };

    const pixel00_loc = blk: {
        const pixel_delta = (pixel_delta_u + pixel_delta_v) * vec.from(0.5);
        break :blk viewport_upper_left + pixel_delta;
    };

    const pixel_samples_scale = blk: {
        const samples_per_pixel_f: f64 = @floatFromInt(samples_per_pixel);
        break :blk 1.0 / samples_per_pixel_f;
    };

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

fn rayColor(
    ray: *const Ray,
    depth: usize,
    world: *const hittable.List,
    rand: std.Random,
) Color3 {
    if (depth <= 0) return Color3{ 0, 0, 0 };

    const hit_record = world.hit(ray, .{ .min = 0.001, .max = mh.infinity });
    if (hit_record) |rec| {
        if (rec.mat.scatter(ray, &rec, rand)) |scatter_result| {
            const scattered, const attenuation = scatter_result;
            return attenuation * rayColor(&scattered, depth - 1, world, rand);
        }
        return .{ 0, 0, 0 };
    }
    const unit_direction = vec.unit(ray.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return blk: {
        const white_component = vec.from(1.0 - a) * Color3{ 1, 1, 1 };
        const blue_component = vec.from(a) * Color3{ 0.5, 0.7, 1 };
        break :blk white_component + blue_component;
    };
}

inline fn getRay(
    self: *const @This(),
    col: usize,
    row: usize,
    rand: std.Random,
) Ray {
    const offset = sampleSquare(rand);
    const pixel_sample = blk: {
        const col_f: f64 = @floatFromInt(col);
        const row_f: f64 = @floatFromInt(row);

        const col_f_offset = col_f + offset[0];
        const row_f_offset = row_f + offset[0];
        const u = vec.from(col_f_offset) * self.pixel_delta_u;
        const v = vec.from(row_f_offset) * self.pixel_delta_v;
        break :blk self.pixel00_loc + u + v;
    };
    const ray_origin = self.center;
    const ray_direction = pixel_sample - ray_origin;
    return Ray.new(ray_origin, ray_direction);
}

/// Return a random 2D offset in [-0.5, 0.5], as a Vec3 with z = 0
inline fn sampleSquare(rand: std.Random) Vec3 {
    return Vec3{ rand.float(f64) - 0.5, rand.float(f64) - 0.5, 0.0 };
}
