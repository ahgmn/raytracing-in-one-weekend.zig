const std = @import("std");
const assert = std.debug.assert;
const Interval = @import("interval.zig").Interval(f64);

const mh = @import("math_helpers.zig");
const Vector = @import("vector.zig");
const Vec3 = Vector.Vec3;
const Color3 = Vector.Color3;
const Point3 = Vector.Point3;

/// Write `color` as u8 with gamma
pub fn writeColor(color: Color3, writer: *std.Io.Writer) !void {
    const r = mh.linearToGamma(color[0]);
    const g = mh.linearToGamma(color[1]);
    const b = mh.linearToGamma(color[2]);

    const intensity: Interval = .{ .min = 0.0, .max = 0.999 };

    const rU8: u8 = @intFromFloat(256 * intensity.clamp(r));
    const gU8: u8 = @intFromFloat(256 * intensity.clamp(g));
    const bU8: u8 = @intFromFloat(256 * intensity.clamp(b));

    try writer.print("{} {} {}\n", .{ rU8, gU8, bU8 });
}

/// `pixel` is in rgba format
pub fn writeColorPixel(color: Color3, pixel: *@Vector(4, u8)) void {
    const r = mh.linearToGamma(color[0]);
    const g = mh.linearToGamma(color[1]);
    const b = mh.linearToGamma(color[2]);

    const intensity: Interval = .{ .min = 0.0, .max = 0.999 };

    const rU8: u8 = @intFromFloat(256 * intensity.clamp(r));
    const gU8: u8 = @intFromFloat(256 * intensity.clamp(g));
    const bU8: u8 = @intFromFloat(256 * intensity.clamp(b));

    pixel.* = .{ rU8, gU8, bU8, 255 };
}

pub fn writePPM(frame: []@Vector(4, u8), width: usize, height: usize, writer: *std.Io.Writer) !void {
    try writer.print("P3\n{} {}\n255\n", .{ width, height });
    for (0..height) |row| {
        for (0..width) |col| {
            const p = frame[width * row + col];
            try writer.print("{} {} {}\n", .{ p[0], p[1], p[2] });
        }
    }
}

/// Write a simple progress bar to `writer`
/// `current` should be `max` when done
/// Example: `[#####......] [current/max]`
pub fn writeProgressBar(current: usize, max: usize, comptime bar_length: u32, writer: *std.Io.Writer) !void {
    assert(current <= max);
    const current_f: f64 = @floatFromInt(current);
    const max_f: f64 = @floatFromInt(max);
    const prog = std.math.clamp(current_f / max_f, 0.0, 1.0);

    const empty_char = '.';
    const full_char = '#';

    const bar_char_amount = bar_length - 2;
    const hash_count: usize = @intFromFloat(@floor(bar_char_amount * prog));

    try writer.writeByte('[');
    for (0..hash_count) |_| {
        try writer.writeByte(full_char);
    }
    for (hash_count..bar_char_amount) |_| {
        try writer.writeByte(empty_char);
    }
    try writer.writeByte(']');

    try writer.print(" [{}/{}]\r", .{ current, max });
}
