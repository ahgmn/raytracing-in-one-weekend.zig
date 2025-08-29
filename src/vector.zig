const std = @import("std");

pub const Vec3 = @Vector(3, f32);
pub const Color3 = Vec3;
pub const Point3 = Vec3;

pub inline fn to(t: f32) Vec3 {
    return @as(Vec3, @splat(t));
}

pub inline fn lenSquared(vec: Vec3) f32 {
    return dot(vec, vec);
    // return vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2];
}

pub inline fn len(vec: Vec3) f32 {
    return @sqrt(lenSquared(vec));
}

pub inline fn unit(vec: Vec3) Vec3 {
    return vec / to(len(vec));
}

pub inline fn dot(u: Vec3, v: Vec3) f32 {
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
pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return .{
        u[1] * v[2] - u[2] * v[1],
        u[2] * v[0] - u[0] * v[2],
        u[0] * v[1] - u[1] * v[0],
    };
}

test "vector dot product" {
    const a = Vec3{ 2, 4, 6 };
    const b = Vec3{ 1, -2, 3 };
    try std.testing.expectApproxEqRel(12.0, dot(a, b), @sqrt(std.math.floatEps(f32)));
}
test "vector cross product" {
    const a = Vec3{ 2, 4, 6 };
    const b = Vec3{ 1, -2, 3 };
    try std.testing.expectEqual(Vec3{ 24, 0, -8 }, cross(a, b));
}

// pub fn Vector3(comptime T: type) type {
//     return struct {
//         inner: @Vector(3, T),

//         pub inline fn new(_x: T, _y: T, _z: T) @This() {
//             return .{ .inner = .{ _x, _y, _z } };
//         }

//         // Getters
//         pub inline fn x(self: @This()) T {
//             return self.inner[0];
//         }
//         pub inline fn y(self: @This()) T {
//             return self.inner[1];
//         }
//         pub inline fn z(self: @This()) T {
//             return self.inner[2];
//         }
//         pub const r = x;
//         pub const g = y;
//         pub const b = z;

//         // Basic
//         pub fn add(u: @This(), v: @This()) @This() {
//             return .{ .inner = u.inner + v.inner };
//         }
//         pub fn adds(u: @This(), t: T) @This() {
//             return .{ .inner = u.inner + @as(@TypeOf(u.inner), @splat(t)) };
//         }
//         pub fn sub(u: @This(), v: @This()) @This() {
//             return .{ .inner = u.inner - v.inner };
//         }
//         pub fn subs(u: @This(), t: T) @This() {
//             return .{ .inner = u.inner - @as(@TypeOf(u.inner), @splat(t)) };
//         }
//         pub fn mul(u: @This(), v: @This()) @This() {
//             return .{ .inner = u.inner * v.inner };
//         }
//         pub fn muls(u: @This(), t: T) @This() {
//             return .{ .inner = u.inner * @as(@TypeOf(u.inner), @splat(t)) };
//         }
//         pub fn div(u: @This(), v: @This()) @This() {
//             return .{ .inner = u.inner / v.inner };
//         }
//         pub fn divs(u: @This(), t: T) @This() {
//             return .{ .inner = u.inner / @as(@TypeOf(u.inner), @splat(t)) };
//         }

//         // Vector
//         pub fn len(self: @This()) T {
//             return std.math.sqrt(self.len_sq());
//         }
//         pub fn len_sq(self: @This()) T {
//             return self.x() * self.x() + self.y() * self.y() + self.z() * self.z();
//         }
//         pub fn dot(u: @This(), v: @This()) T {
//             return u.x() * v.x() + u.y() * v.y() + u.z() * v.z();
//         }
//         pub fn cross(u: @This(), v: @This()) @This() {
//             return .{ .inner = .{
//                 u.y * v.z - u.z * v.y,
//                 u.z * v.x - u.x * v.z,
//                 u.x * v.y - u.y * v.y,
//             } };
//         }
//         pub fn unit(self: @This()) @This() {
//             return self.divs(self.len());
//         }

//         pub fn format(
//             self: @This(),
//             comptime fmt: []const u8,
//             options: std.fmt.FormatOptions,
//             writer: anytype,
//         ) !void {
//             _ = fmt; // unused here
//             _ = options; // could be used to change precision, etc.
//             try writer.print("({d:.3}, {d:.3}, {d:.3})", .{
//                 self.x(), self.y(), self.z(),
//             });
//         }
//     };
// }
