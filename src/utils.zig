const m = @import("std").math;
const Vector = @import("vector.zig");
const Vec3f = Vector.Vec3f;
const Col3f = Vector.Col3f;

pub fn to_f32(comptime T: type, from: T) f32 {
    return @as(f32, @floatFromInt(from));
}

pub fn clamp_to_u8(comptime T: type, from: T) u8 {
    return @as(u8, @intFromFloat(m.clamp(from, 0.0, 1.0) * 255.999));
}

pub fn write_col_to(col: Col3f, writer: anytype) !void {
    const r: u8 = clamp_to_u8(f32, col.r());
    const g: u8 = clamp_to_u8(f32, col.g());
    const b: u8 = clamp_to_u8(f32, col.b());
    try writer.print("{} {} {}\n", .{ r, g, b });
}
