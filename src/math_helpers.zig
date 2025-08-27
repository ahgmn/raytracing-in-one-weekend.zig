const std = @import("std");
const m = @import("std").math;

const Vector = @import("vector.zig");
const Vec3 = Vector.Vec3;
const Color3 = Vector.Color3;
const Point3 = Vector.Point3;

pub fn toF32(comptime T: type, from: T) f32 {
    return @as(f32, @floatFromInt(from));
}

pub const infinity = m.inf(f32);

pub fn clampToU8(comptime T: type, from: T) u8 {
    return @as(u8, @intFromFloat(m.clamp(from, 0.0, 1.0) * 255.999));
}

pub inline fn degreesToRadians(degrees: f32) f32 {
    return degrees * m.pi / 180.0;
}
