const std = @import("std");

pub const Vec3f = Vector3("Vec3f", f32);
pub const Col3f = Vector3("Col3f", f32);

pub fn Vector3(comptime TypeName: []const u8, comptime T: type) type {
    return struct {
        inner: @Vector(3, T),
        pub const name = TypeName;

        pub inline fn new(_x: T, _y: T, _z: T) @This() {
            return .{ .inner = .{ _x, _y, _z } };
        }

        // Getters
        pub inline fn x(self: @This()) T {
            return self.inner[0];
        }
        pub inline fn y(self: @This()) T {
            return self.inner[1];
        }
        pub inline fn z(self: @This()) T {
            return self.inner[2];
        }
        pub inline fn r(self: @This()) T {
            return self.inner[0];
        }
        pub inline fn g(self: @This()) T {
            return self.inner[1];
        }
        pub inline fn b(self: @This()) T {
            return self.inner[2];
        }

        // Basic
        pub fn add(u: @This(), v: @This()) @This() {
            return .{ .inner = u.inner + v.inner };
        }
        pub fn adds(u: @This(), t: T) @This() {
            return .{ .inner = u.inner + @as(@This(), @splat(t)) };
        }
        pub fn sub(u: @This(), v: @This()) @This() {
            return .{ .inner = u.inner - v.inner };
        }
        pub fn subs(u: @This(), t: T) @This() {
            return .{ .inner = u.inner - @as(@This(), @splat(t)) };
        }
        pub fn mul(u: @This(), v: @This()) @This() {
            return .{ .inner = u.inner * v.inner };
        }
        pub fn muls(u: @This(), t: T) @This() {
            return .{ .inner = u.inner * @as(@This(), @splat(t)) };
        }
        pub fn div(u: @This(), v: @This()) @This() {
            return .{ .inner = u.inner / v.inner };
        }
        pub fn divs(u: @This(), t: T) @This() {
            return .{ .inner = u.inner / @as(@This(), @splat(t)) };
        }

        // Vector
        pub fn len(self: @This()) T {
            return std.math.sqrt(self.len_sq());
        }
        pub fn len_sq(self: @This()) T {
            return self.x * self.x + self.y * self.y + self.z * self.z;
        }
        pub fn dot(u: @This(), v: @This()) T {
            return u.x * v.x + u.y * v.y + u.z * v.z;
        }
        pub fn cross(u: @This(), v: @This()) @This() {
            return .{ .inner = .{
                u.y * v.z - u.z * v.y,
                u.z * v.x - u.x * v.z,
                u.x * v.y - u.y * v.y,
            } };
        }
        pub fn unit(self: @This()) @This() {
            return self / self.len();
        }

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt; // unused here
            _ = options; // could be used to change precision, etc.
            try writer.print("({d:.3}, {d:.3}, {d:.3})", .{
                self.x(), self.y(), self.z(),
            });
        }
    };
}
