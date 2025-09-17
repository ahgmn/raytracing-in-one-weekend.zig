const mh = @import("math_helpers.zig");

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

        pub fn clamp(self: *const @This(), x: T) T {
            if (x < self.min) return self.min;
            if (x > self.max) return self.max;
            return x;
        }

        pub fn empty(_: *const @This()) @This() {
            return .{ .min = mh.infinity, .max = -mh.infinity };
        }

        pub fn universe(_: *const @This()) @This() {
            return .{ .min = -mh.infinity, .max = mh.infinity };
        }
    };
}
