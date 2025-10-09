const std = @import("std");
const print = std.debug.print;

const memory = @import("memory.zig");
const _struct = @import("struct.zig");
const matrix = @import("matrix.zig");
const sparse = @import("sparse.zig");

pub fn main() !void {
    const ns = [_]usize{ 10, 100 };
    const its = 10;
    const runs = 3;
    try runBenchmark("Memory implementation", memory, &ns, its, runs);
    try runBenchmark("Struct implementation", _struct, &ns, its, runs);
    try runBenchmark("Matrix implementation", matrix, &ns, its, runs);
    try runBenchmark("Sparse implementation", sparse, &ns, its, runs);
}

fn runBenchmark(
    name: []const u8,
    implementation: anytype,
    ns: []const usize,
    its: i32,
    runs: usize,
) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    print("{s}\n", .{name});
    for (ns) |n| {
        print("n: {}\n", .{n});
        var start = std.time.nanoTimestamp();
        var gol = try implementation.GOL.init(allocator, n, n);
        defer gol.deinit();
        var end = std.time.nanoTimestamp();
        var elapsed_ns = end - start;
        var elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(std.time.ns_per_s));
        print("init time: {d:.4}s\n", .{elapsed_s});
        var total_time: f64 = 0;
        for (0..runs) |_| {
            start = std.time.nanoTimestamp();
            try gol.update(its, false);
            end = std.time.nanoTimestamp();
            elapsed_ns = end - start;
            elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(std.time.ns_per_s));
            total_time += elapsed_s;
        }
        const its_per_s = @as(f64, @floatFromInt(runs)) / total_time;
        print("its/s: {d:.4}\n", .{its_per_s});
    }
}
