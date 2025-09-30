const std = @import("std");

const Ray = @import("Ray.zig");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;
const Interval = @import("interval.zig").Interval(f64);
const material = @import("material.zig");

pub const Object = union(enum) {
    sphere: Sphere,

    fn hit(self: *const Object, ray: *const Ray, ray_t: Interval) ?HitRecord {
        switch (self.*) {
            .sphere => |sphere| {
                return sphere.hit(ray, ray_t);
            },
        }
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f64,
    mat: *material.Material,

    pub fn hit(self: *const Sphere, ray: *const Ray, ray_t: Interval) ?HitRecord {
        const oc = self.center - ray.orig;
        const a = vec.lenSquared(ray.dir);
        const h = vec.dot(ray.dir, oc);
        const c = vec.lenSquared(oc) - self.radius * self.radius;
        const discriminant = h * h - a * c;
        if (discriminant < 0) {
            return null;
        }
        const sqrtd = @sqrt(discriminant);

        var root = (h - sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!ray_t.surrounds(root)) {
                return null;
            }
        }

        const p = ray.at(root);
        const outward_normal = (p - self.center) / vec.from(self.radius);
        var record = HitRecord{
            .t = root,
            .p = p,
            .normal = (p - self.center) / vec.from(self.radius),
            .front_face = undefined,
            .mat = self.mat,
        };
        record.setFaceNormal(ray, outward_normal);
        return record;
    }
};

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    mat: *material.Material,
    t: f64,
    front_face: bool,

    /// note!: `outward_normal` is assumed to be a unit vector
    fn setFaceNormal(
        self: *@This(),
        ray: *const Ray,
        outward_normal: Vec3,
    ) void {
        self.front_face = vec.dot(ray.dir, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else -outward_normal;
    }
};

pub const List = struct {
    objects: std.ArrayList(Object),

    pub fn hit(
        self: *const @This(),
        ray: *const Ray,
        ray_t: Interval,
    ) ?HitRecord {
        var record: ?HitRecord = null;
        var closest_so_far = ray_t.max;
        for (self.objects.items) |object| {
            const temp_record = object.hit(
                ray,
                .{ .min = ray_t.min, .max = closest_so_far },
            );
            if (temp_record) |rec| {
                closest_so_far = rec.t;
                record = rec;
            } else {}
        }
        return record;
    }

    pub fn clearAndFree(self: @This()) !void {
        self.objects.clearAndFree();
    }

    pub fn add(
        self: *@This(),
        allocator: std.mem.Allocator,
        object: Object,
    ) !void {
        try self.objects.append(allocator, object);
    }

    pub fn init(allocator: std.mem.Allocator) !@This() {
        return .{
            .objects = try std.ArrayList(Object).initCapacity(allocator, 16),
        };
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.objects.deinit(allocator);
    }
};

test "sphere allocation" {
    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    var hittable_list = try List.init(allocator);
    defer hittable_list.deinit(allocator);

    const s = Object{ .sphere = .{ .center = Point3{ 0, 0, -1 }, .radius = 1 } };
    try hittable_list.add(allocator, s);

    std.debug.assert(hittable_list.objects.items[0].sphere.radius == 1);
}
