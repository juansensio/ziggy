const std = @import("std");
const print = std.debug.print;

const memory = @import("memory.zig");
const _struct = @import("struct.zig");

// Generic benchmark function that works with any function that has the signature:
// fn(usize, usize, i32, bool) anytype
fn runBenchmark(
    name: []const u8,
    func: anytype,
    ns: []const usize,
    its: i32,
    runs: usize,
) !void {
    print("{s}\n", .{name});
    for (ns) |n| {
        var total_time: f64 = 0;
        for (0..runs) |_| {
            const start = std.time.nanoTimestamp();
            try func(n, n, its, false);
            const end = std.time.nanoTimestamp();
            const elapsed_ns = end - start;
            const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(std.time.ns_per_s));
            total_time += elapsed_s;
        }
        const its_per_s = @as(f64, @floatFromInt(runs)) / total_time;
        print("n: {}, its/s: {d:.4}\n", .{ n, its_per_s });
    }
}

pub fn main() !void {
    const ns = [_]usize{ 10, 100, 500 };
    const its = 10;
    const runs = 10;

    // Benchmark memory implementation
    try runBenchmark("Memory implementation", memory.memmory_implementation, &ns, its, runs);

    // Benchmark struct implementation
    try runBenchmark("Struct implementation", _struct.struct_implementation, &ns, its, runs);
}
