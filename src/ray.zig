const std = @import("std");

const Vector = @import("vector.zig");
const Vec3f = Vector.Vec3;
const Color3 = Vector.Color3;
const Point3 = Vector.Point3;

pub const Ray3f = struct {
    orig: Point3,
    dir: Vec3f,
    pub inline fn new(orig: Point3, dir: Vec3f) @This() {
        return .{ .orig = orig, .dir = dir };
    }
    pub fn at(self: @This(), t: f32) Point3 {
        return self.orig.add(self.dir.muls(t));
    }
};
