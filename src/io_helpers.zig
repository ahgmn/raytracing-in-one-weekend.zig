const std = @import("std");
const m = @import("std").math;
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

pub fn writeProgressBar(current: usize, max: usize, comptime bar_length: u32, writer: *std.Io.Writer) !void {
    const prog = m.clamp(mh.toF32(usize, current) / mh.toF32(usize, max), 0.0, 1.0);
    const final_string: [*c]const u8 = "Done!";
    const final_string_length = comptime std.mem.len(final_string);
    if (bar_length < final_string_length + 2) {
        @compileError("bar_length is too short");
    }
    const dash_count = comptime (bar_length - (final_string_length + 2)) / 2;

    const bar_char_amount = bar_length - 2;
    const hash_count = @as(usize, @intFromFloat(@floor(bar_char_amount * prog)));

    try writer.print("\x1B[2K\r", .{});
    if (prog == 1.0) {
        inline for (0..dash_count) |_| {
            try writer.writeByte('-');
        }
        try writer.print(" {s} ", .{final_string});
        inline for (0..dash_count) |_| {
            try writer.writeByte('-');
        }
    } else {
        try writer.writeByte('[');
        for (0..hash_count) |_| {
            try writer.writeByte('#');
        }
        for (0..(bar_char_amount - hash_count)) |_| {
            try writer.writeByte(' ');
        }
        try writer.writeByte(']');
    }
}
