pub fn Vec(comptime dim: usize, comptime T: type) type {
    return struct {
        data: [dim]T,

        pub fn init(values: [dim]T) @This() {
            return @This(){ .data = values };
        }

        pub fn add(first: @This(), second: @This()) @This() {
            var result = @This(){ .data = undefined };
            for (0..dim) |i| {
                result.data[i] = first.data[i] + second.data[i];
            }
            return result;
        }
    };
}
