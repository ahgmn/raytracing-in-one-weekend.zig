const std = @import("std");
const assert = std.debug.assert;
const mh = @import("math_helpers.zig");

pub const Vec3 = @Vector(3, f64);
pub const Color3 = Vec3;
pub const Point3 = Vec3;

pub inline fn from(t: f64) Vec3 {
    return @as(Vec3, @splat(t));
}

pub inline fn lenSquared(vec: Vec3) f64 {
    return dot(vec, vec);
}

pub inline fn len(vec: Vec3) f64 {
    return @sqrt(lenSquared(vec));
}

pub inline fn unit(vec: Vec3) Vec3 {
    return vec / from(len(vec));
}

pub inline fn dot(u: Vec3, v: Vec3) f64 {
    return @reduce(.Add, u * v);
}

/// Used to calculate the cross product between
/// 2 3-dimensional vectors. The cross product can
/// be expressed as the determinant of the 3x3
/// matrix in the form:
///         +-----+-----+-----+
///         |  x  |  y  |  z  |
///         +-----+-----+-----+
///         | u.x | u.y | u.z |
///         +-----+-----+-----+
///         | v.x | v.y | v.z |
///         +-----+-----+-----+
pub inline fn cross(u: Vec3, v: Vec3) Vec3 {
    return .{
        u[1] * v[2] - u[2] * v[1],
        u[2] * v[0] - u[0] * v[2],
        u[0] * v[1] - u[1] * v[0],
    };
}

pub inline fn random(rand: std.Random) Vec3 {
    const ElemType = @typeInfo(@TypeOf(Vec3)).vector.child;
    return Vec3{ rand.float(ElemType), rand.float(ElemType), rand.float(ElemType) };
}

pub inline fn randomInRange(
    min: f64,
    max: f64,
    rand: std.Random,
) Vec3 {
    assert(min <= max);
    return Vec3{
        mh.randomInRange(min, max, rand),
        mh.randomInRange(min, max, rand),
        mh.randomInRange(min, max, rand),
    };
}

pub inline fn randomUnit(rand: std.Random) Vec3 {
    return while (true) {
        const p = randomInRange(-1, 1, rand);
        const lensq = lenSquared(p);
        if (1e-160 < lensq and lensq <= 1)
            break p / from(@sqrt(lensq));
    };
}

pub inline fn randomOnHemisphere(normal: Vec3, rand: std.Random) Vec3 {
    const onUnitSphere = randomUnit(rand);
    if (dot(onUnitSphere, normal) > 0.0) {
        return onUnitSphere;
    } else {
        return -onUnitSphere;
    }
}

test "vector dot product" {
    const a = Vec3{ 2, 4, 6 };
    const b = Vec3{ 1, -2, 3 };
    try std.testing.expectApproxEqRel(12.0, dot(a, b), @sqrt(std.math.floatEps(f64)));
}
test "vector cross product" {
    const a = Vec3{ 2, 4, 6 };
    const b = Vec3{ 1, -2, 3 };
    try std.testing.expectEqual(Vec3{ 24, 0, -8 }, cross(a, b));
}
