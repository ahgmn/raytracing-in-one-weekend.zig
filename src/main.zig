const std = @import("std");

const Ray = @import("ray.zig");
const Ray3f = Ray.Ray3f;
const util = @import("utils.zig");
const Vector = @import("vector.zig");
const Vec3f = Vector.Vec3f;
const Col3f = Vector.Col3f;
const Point3f = Vector.Point3f;

var image_width: usize = 950;
var image_height: usize = 600;
inline fn aspect_ratio() f32 {
    return util.to_f32(usize, image_width) / util.to_f32(usize, image_height);
}
var viewport_height: f32 = 2.0;
inline fn viewport_width() f32 {
    return viewport_height * aspect_ratio();
}
var focal_length: f32 = 2.0;

pub fn ray_color(ray: *const Ray3f) Col3f {
    const unit_dir = ray.dir.unit();
    const a = 0.5 * (unit_dir.y() + 1.0);
    return Col3f.new(1, 1, 1).muls(1.0 - a).add(Col3f.new(0.5, 0.7, 1).muls(a));
}

pub fn main() !void {
    // SETUP ----
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const stderr_file = std.io.getStdErr().writer();
    var bw_err = std.io.bufferedWriter(stderr_file);
    const stderr = bw_err.writer();
    // SETUP DONE

    const camera_center = Point3f.new(0, 0, 0);

    var viewport_u = Vec3f.new(viewport_width(), 0, 0);
    var viewport_v = Vec3f.new(0, -viewport_height, 0);

    var pixel_delta_u = viewport_u.divs(util.to_f32(usize, image_width));
    var pixel_delta_v = viewport_v.divs(util.to_f32(usize, image_height));

    var viewport_upper_left = camera_center
        .sub(Vec3f.new(0, 0, focal_length))
        .sub(viewport_u.divs(2))
        .sub(viewport_v.divs(2));
    var pixel00_loc = viewport_upper_left
        .add(pixel_delta_u
        .add(pixel_delta_v)
        .muls(0.5));

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |row| {
        try stderr.print("\x1B[2K\rScanlines remaining: {}", .{image_height - row});
        try bw_err.flush();
        for (0..image_width) |col| {
            const colf: f32 = util.to_f32(usize, col);
            const rowf: f32 = util.to_f32(usize, row);
            const pixel_center = pixel00_loc
                .add(pixel_delta_u.muls(colf))
                .add(pixel_delta_v.muls(rowf));
            const ray_direction = pixel_center.sub(camera_center);
            const ray = Ray3f.new(camera_center, ray_direction);

            const pixel_color = ray_color(&ray);
            try util.write_col(pixel_color, stdout);
        }
    }
    try stderr.print("\x1B[2K\r---- Done! ----\n", .{});

    try bw_err.flush();
    try bw.flush();
}
