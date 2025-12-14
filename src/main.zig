const std = @import("std");
const assert = std.debug.assert;

const zwd = @import("zwdisplay");

const Camera = @import("Camera.zig");
const hittable = @import("hittable.zig");
const ih = @import("io_helpers.zig");
const material = @import("material.zig");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;

const image_width: usize = 200;
const aspect_ratio: f64 = 16.0 / 9.0;
const samples_per_pixel = 10;
const max_depth = 10;
const vfov = 20.0;
const lookfrom = Point3{ 13, 2, 3 };
const lookat = Point3{ 0, 0, 0 };
const vup = Vec3{ 0, 1, 0 };
const defocus_angle = 0.6;
const focus_dist = 10.0;

pub fn main() !void {
    // Allocation
    // --------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------

    // Printing
    // --------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;
    // --------------------------------------------

    // File
    // --------------------------------------------
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
    // --------------------------------------------

    // Random
    // --------------------------------------------
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    // --------------------------------------------

    // World
    // --------------------------------------------
    var world = try hittable.List.init(allocator);
    defer world.deinit(allocator);

    var material_list = try std.ArrayList(*material.Material).initCapacity(allocator, 200);
    defer {
        for (material_list.items) |mat| {
            allocator.destroy(mat);
        }
        material_list.deinit(allocator);
    }

    var ground_mat: material.Material = .{
        .lambertian = .{ .albedo = .{ 0.5, 0.5, 0.5 } },
    };
    try world.add(allocator, .{
        .sphere = .{
            .center = .{ 0, -1000, 0 },
            .radius = 1000,
            .mat = &ground_mat,
        },
    });

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = rand.float(f64);
            const a_f: f64 = @floatFromInt(a);
            const b_f: f64 = @floatFromInt(b);
            const center = Point3{
                a_f + 0.9 * rand.float(f64),
                0.2,
                b_f + 0.9 * rand.float(f64),
            };
            if (choose_mat < 0.8) {
                const albedo = vec.randomInRange(0, 1, rand) * vec.randomInRange(0, 1, rand);
                const mat = try allocator.create(material.Material);
                mat.* = material.Material{ .lambertian = .{ .albedo = albedo } };
                try material_list.append(allocator, mat);
                try world.add(allocator, hittable.Object{
                    .sphere = .{ .center = center, .radius = 0.2, .mat = mat },
                });
            } else if (choose_mat < 0.95) {
                const albedo = vec.randomInRange(0.5, 1, rand);
                const fuzz = rand.float(f64) / 2.0;
                const mat = try allocator.create(material.Material);
                mat.* = .{ .metal = .{ .albedo = albedo, .fuzz = fuzz } };
                try material_list.append(allocator, mat);
                try world.add(allocator, hittable.Object{
                    .sphere = .{ .center = center, .radius = 0.2, .mat = mat },
                });
            } else {
                const mat = try allocator.create(material.Material);
                mat.* = .{ .dielectric = .{ .refraction_index = 1.5 } };
                try material_list.append(allocator, mat);
                try world.add(allocator, hittable.Object{
                    .sphere = .{ .center = center, .radius = 0.2, .mat = mat },
                });
            }
        }
    }

    var mat1: material.Material = .{
        .dielectric = .{ .refraction_index = 1.5 },
    };
    try world.add(allocator, .{
        .sphere = .{
            .center = .{ 0, 1, 0 },
            .radius = 1,
            .mat = &mat1,
        },
    });

    var mat2: material.Material = .{
        .lambertian = .{ .albedo = .{ 0.4, 0.2, 0.1 } },
    };
    try world.add(allocator, .{
        .sphere = .{
            .center = .{ -4, 1, 0 },
            .radius = 1,
            .mat = &mat2,
        },
    });

    var mat3: material.Material = .{
        .metal = .{ .albedo = .{ 0.7, 0.6, 0.5 }, .fuzz = 0.0 },
    };
    try world.add(allocator, .{
        .sphere = .{
            .center = .{ 4, 1, 0 },
            .radius = 1,
            .mat = &mat3,
        },
    });
    // --------------------------------------------

    const camera = Camera.init(
        image_width,
        aspect_ratio,
        samples_per_pixel,
        max_depth,
        vfov,
        lookfrom,
        lookat,
        vup,
        defocus_angle,
        focus_dist,
    );

    const frame = try allocator.alloc(@Vector(4, u8), camera.image_width * camera.image_height);
    defer allocator.free(frame);

    // Window
    // --------------------------------------------
    var app_state: zwd.AppState = undefined;
    var render_progress: Camera.RenderProgress = .{};
    var user_data: UserData = .{
        .frame = frame,
        .render_progress = &render_progress,
        .render_width = camera.image_width,
        .render_height = camera.image_height,
    };
    try app_state.init(draw, 800, 800 / aspect_ratio, &user_data);
    defer app_state.deinit();
    // --------------------------------------------

    _ = try std.Thread.spawn(.{}, run, .{
        &camera,
        &world,
        rand,
        frame,
        &render_progress,
        stdout,
        f,
    });

    try app_state.run();

    try ih.writePPM(frame, camera.image_width, camera.image_height, f);

    try stderr.flush();
    try stdout.flush();
    try f.flush();
}

fn run(
    camera: *const Camera,
    world: *const hittable.List,
    rand: std.Random,
    frame: []@Vector(4, u8),
    progress: *Camera.RenderProgress,
    stdout: *std.Io.Writer,
    file: *std.Io.Writer,
) !void {
    try camera.render(world, rand, frame, stdout, progress);
    progress.done.store(true, .release);
    try ih.writePPM(frame, camera.image_width, camera.image_height, file);
}

const UserData = struct {
    frame: []@Vector(4, u8),
    render_progress: *Camera.RenderProgress,
    render_width: usize,
    render_height: usize,
};

fn draw(
    pixels: []u32,
    resolution: zwd.Resolution,
    dt_s: f32,
    input_state: *const zwd.InputState,
    userdata: *anyopaque,
) void {
    _ = dt_s;
    _ = input_state;

    const convertPixel = struct {
        inline fn convert(p: @Vector(4, u8)) u32 {
            const r: u32 = p[0];
            const g: u32 = p[1];
            const b: u32 = p[2];
            const a: u32 = p[3];
            return a << 24 | r << 16 | g << 8 | b << 0;
        }
    }.convert;

    const data: *UserData = @ptrCast(@alignCast(userdata));
    @memset(pixels, 0xFF000000);

    const src_width = data.render_width;
    const src_height = data.render_height;

    const dst_width: usize = @intCast(resolution.width);
    const dst_height: usize = @intCast(resolution.height);

    const scale_x: f64 = @as(f64, @floatFromInt(src_width)) / @as(f64, @floatFromInt(dst_width));
    const scale_y: f64 = @as(f64, @floatFromInt(src_height)) / @as(f64, @floatFromInt(dst_height));

    const rows_done = data.render_progress.rows_done.load(.acquire);
    if (rows_done == 0) return;
    const rows_dst: usize = blk: {
        const rows_done_f: f64 = @floatFromInt(rows_done);
        break :blk @intFromFloat(rows_done_f * 1 / scale_y);
    };
    for (0..rows_dst) |row| {
        const src_y: usize = blk: {
            const row_f: f64 = @floatFromInt(row);
            break :blk @intFromFloat(row_f * scale_y);
        };
        for (0..dst_width) |col| {
            const src_x: usize = blk: {
                const col_f: f64 = @floatFromInt(col);
                break :blk @intFromFloat(col_f * scale_x);
            };
            pixels[dst_width * row + col] = convertPixel(data.frame[src_width * src_y + src_x]);
        }
    }
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
