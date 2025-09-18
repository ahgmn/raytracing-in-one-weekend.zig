const std = @import("std");

const vec = @import("vector.zig");
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const Point3 = vec.Point3;

orig: Point3,
dir: Vec3,

pub inline fn new(orig: Point3, dir: Vec3) @This() {
    return .{ .orig = orig, .dir = dir };
}
pub fn at(self: @This(), t: f64) Point3 {
    return self.orig + (self.dir * vec.from(t));
}
