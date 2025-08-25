const m = @import("std").math;
pub fn to_f32(comptime T: type, from: T) f32 {
    return @as(f32, @floatFromInt(from));
}

pub fn clamp_to_u8(comptime T: type, from: T) u8 {
    return @as(u8, @intFromFloat(m.clamp(from, 0.0, 1.0) * 255.999));
}
