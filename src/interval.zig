// const std = @import("std");
// pub const Interval

const infinity = @import("math_helpers.zig").infinity;

pub fn Interval(comptime T: type) type {
    return struct {
        min: T,
        max: T,

        pub fn size(self: *const @This()) T {
            const range = self.max - self.min;
            return range;
        }

        pub fn contains(self: *const @This(), x: T) bool {
            return self.min <= x and x <= self.max;
        }

        pub fn surrounds(self: *const @This(), x: T) bool {
            return self.min < x and x < self.max;
        }

        pub fn empty(_: *const @This()) @This() {
            return .{ .min = infinity, .max = -infinity };
        }

        pub fn universe(_: *const @This()) @This() {
            return .{ .min = -infinity, .max = infinity };
        }
    };
}
