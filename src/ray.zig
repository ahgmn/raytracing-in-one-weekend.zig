const std = @import("std");

const Vector = @import("vector.zig");
const Vec3f = Vector.Vec3f;
const Col3f = Vector.Col3f;
const Point3f = Vector.Point3f;

pub const Ray3f = struct {
    orig: Point3f,
    dir: Vec3f,
    pub inline fn new(orig: Point3f, dir: Vec3f) @This() {
        return .{ .orig = orig, .dir = dir };
    }
    pub fn at(self: @This(), t: f32) Point3f {
        return self.orig.add(self.dir.muls(t));
    }
};
