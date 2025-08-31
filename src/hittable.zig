//! TODO: Docstring
const std = @import("std");

const Ray = @import("Ray.zig");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;
const Interval = @import("interval.zig").Interval(f32);

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    t: f32,
    front_face: bool,

    /// note!: `outward_normal` is assumed to be a unit vector
    pub fn setFaceNormal(self: *@This(), ray: *const Ray, outward_normal: *const Vec3) void {
        self.front_face = vec.dot(ray.dir, outward_normal.*) < 0;
        self.normal = if (self.front_face) outward_normal.* else -outward_normal.*;
    }
};

pub const List = struct {
    objects: std.ArrayList(Object),

    pub fn hit(self: *const @This(), ray: *const Ray, ray_t: Interval) ?HitRecord {
        var record: ?HitRecord = null;
        var closest_so_far = ray_t.max;
        for (self.objects.items) |object| {
            const temp_record = object.hit(ray, .{ .min = ray_t.min, .max = closest_so_far });
            if (temp_record) |rec| {
                closest_so_far = rec.t;
                record = rec;
            } else {}
        }
        return record;
    }

    pub fn clearAndFree(self: *@This()) !void {
        for (self.objects.items) |object| {
            object.deinit(self.objects.allocator);
        }
        self.objects.clearAndFree();
    }

    pub fn add(self: *@This(), object: Object) !void {
        try self.objects.append(object);
    }

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .objects = std.ArrayList(Object).init(allocator) };
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        for (self.objects.items) |*object| {
            object.deinit(allocator);
        }
        self.objects.deinit();
    }
};

pub const Object = struct {
    ptr: *anyopaque,
    hitFn: *const fn (ptr: *anyopaque, ray: *const Ray, ray_t: Interval) ?HitRecord,
    deinitFn: ?*const fn (ptr: *anyopaque, allocator: std.mem.Allocator) void,

    pub fn hit(self: *const @This(), ray: *const Ray, ray_t: Interval) ?HitRecord {
        return self.hitFn(self.ptr, ray, ray_t);
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        if (self.deinitFn) |_deinitFn| _deinitFn(self.ptr, allocator);
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f32,

    fn hitFn(ptr: *anyopaque, ray: *const Ray, ray_t: Interval) ?HitRecord {
        const self: *Sphere = @ptrCast(@alignCast(ptr));
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
        };
        record.setFaceNormal(ray, &outward_normal);
        return record;
    }

    fn deinitFn(ptr: *anyopaque, allocator: std.mem.Allocator) void {
        const self: *Sphere = @ptrCast(@alignCast(ptr));
        allocator.destroy(self);
    }

    pub fn init(allocator: std.mem.Allocator, center: Point3, radius: f32) !Object {
        const s = try allocator.create(Sphere);
        const rad = @max(0, radius);
        s.* = Sphere{ .center = center, .radius = rad };
        return .{ .ptr = s, .hitFn = hitFn, .deinitFn = deinitFn };
    }
};

test "sphere allocation" {
    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    var hittable_list = List.init(allocator);
    defer _ = hittable_list.deinit(allocator);

    var s = Sphere.init(allocator, Point3{ 0, 0, -1 }, 0.2);
    try hittable_list.add(&s);

    std.debug.print("The sphere is: {}", .{hittable_list.objects.items[0]});
}
