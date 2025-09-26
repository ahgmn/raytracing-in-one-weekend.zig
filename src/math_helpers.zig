const m = @import("std").math;
const std = @import("std");

const Vector = @import("vector.zig");
const Vec3 = Vector.Vec3;
const Color3 = Vector.Color3;
const Point3 = Vector.Point3;

pub const infinity = m.inf(f64);

pub inline fn randomInRange(min: f64, max: f64, rand: std.Random) f64 {
    return min + (max - min) * rand.float(f64);
}

pub inline fn degreesToRadians(degrees: f64) f64 {
    return degrees * m.pi / 180.0;
}

pub inline fn linearToGamma(linearComponent: f64) f64 {
    if (linearComponent > 0.0)
        return @sqrt(linearComponent);
    return 0.0;
}
