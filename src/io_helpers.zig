const std = @import("std");
const assert = std.debug.assert;

const mh = @import("math_helpers.zig");
const Vector = @import("vector.zig");
const Vec3 = Vector.Vec3;
const Color3 = Vector.Color3;
const Point3 = Vector.Point3;

pub fn writeCol(col: Color3, writer: *std.Io.Writer) !void {
    const r: u8 = mh.clampToU8(f32, col[0]);
    const g: u8 = mh.clampToU8(f32, col[1]);
    const b: u8 = mh.clampToU8(f32, col[2]);
    try writer.print("{} {} {}\n", .{ r, g, b });
}

/// Write a simple progress bar to `writer`
/// `current` should be `max` when done
pub fn writeProgressBar(current: usize, max: usize, comptime bar_length: u32, writer: *std.Io.Writer) !void {
    assert(current <= max);
    const prog = std.math.clamp(mh.toF32(usize, current) / mh.toF32(usize, max), 0.0, 1.0);

    const empty_char = '.';
    const full_char = '#';

    const bar_char_amount = bar_length - 2;
    const hash_count = @as(usize, @intFromFloat(@floor(bar_char_amount * prog)));

    try writer.writeByte('[');
    for (0..hash_count) |_| {
        try writer.writeByte(full_char);
    }
    for (hash_count..bar_char_amount) |_| {
        try writer.writeByte(empty_char);
    }
    try writer.writeByte(']');

    try writer.print(" [{}/{}]\r", .{ current, max });
    try writer.flush();
}
