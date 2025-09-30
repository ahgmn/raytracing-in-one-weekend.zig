const std = @import("std");

const Ray = @import("Ray.zig");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;
const Interval = @import("interval.zig").Interval(f64);
const hittable = @import("hittable.zig");

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    pub inline fn scatter(
        self: *const @This(),
        ray_in: *const Ray,
        hit_record: *const hittable.HitRecord,
        rand: std.Random,
    ) ?struct { Ray, Color3 } { // TODO: I am  not sure this is a performant approach
        switch (self.*) {
            .lambertian => |lambertian| {
                return lambertian.scatter(ray_in, hit_record, rand);
            },
            .metal => |metal| {
                return metal.scatter(ray_in, hit_record, rand);
            },
            .dielectric => |dielectric| {
                return dielectric.scatter(ray_in, hit_record, rand);
            },
        }
    }
};

pub const Lambertian = struct {
    albedo: Color3,

    pub inline fn scatter(
        self: *const @This(),
        ray_in: *const Ray,
        hit_record: *const hittable.HitRecord,
        rand: std.Random,
    ) ?struct { Ray, Color3 } {
        _ = ray_in;
        var scatter_direction = hit_record.normal + vec.randomUnit(rand);
        if (vec.nearZero(scatter_direction)) {
            scatter_direction = hit_record.normal;
        }
        const scattered = Ray.new(hit_record.p, scatter_direction);
        const attenuation = self.albedo;
        return .{ scattered, attenuation };
    }
};

pub const Metal = struct {
    albedo: Color3,
    /// assumed to be under 1
    fuzz: f64,

    pub inline fn scatter(
        self: *const @This(),
        ray_in: *const Ray,
        hit_record: *const hittable.HitRecord,
        rand: std.Random,
    ) ?struct { Ray, Color3 } {
        var reflected = vec.reflect(ray_in.dir, hit_record.normal);
        reflected = vec.unit(reflected) +
            (vec.from(self.fuzz) * vec.randomUnit(rand));
        const scattered = Ray.new(hit_record.p, reflected);
        const attenuation = self.albedo;
        if (vec.dot(scattered.dir, hit_record.normal) > 0)
            return .{ scattered, attenuation };
        return null;
    }
};

pub const Dielectric = struct {
    refraction_index: f64,

    pub inline fn scatter(
        self: *const @This(),
        ray_in: *const Ray,
        hit_record: *const hittable.HitRecord,
        rand: std.Random,
    ) ?struct { Ray, Color3 } {
        _ = rand;
        const attenuation = Color3{ 1, 1, 1 };
        const ri = blk: {
            break :blk if (hit_record.front_face)
                1.0 / self.refraction_index
            else
                self.refraction_index;
        };
        const unit_direction = vec.unit(ray_in.dir);

        const cos_theta = @min(vec.dot(-unit_direction, hit_record.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = ri * sin_theta > 1.0;
        const direction = blk: {
            break :blk if (cannot_refract)
                vec.reflect(unit_direction, hit_record.normal)
            else
                vec.refract(unit_direction, hit_record.normal, ri);
        };

        const scattered = Ray.new(hit_record.p, direction);

        return .{ scattered, attenuation };
    }
};
