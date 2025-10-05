const std = @import("std");
const assert = std.debug.assert;

const Camera = @import("Camera.zig");
const hittable = @import("hittable.zig");
const vec = @import("vector.zig");
const ih = @import("io_helpers.zig");
const material = @import("material.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;

const image_width: usize = 100;
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

    try camera.render(&world, rand, frame, stdout);

    try ih.writePPM(frame, camera.image_width, camera.image_height, f);

    try stderr.flush();
    try stdout.flush();
    try f.flush();
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
