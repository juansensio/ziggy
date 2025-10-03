const std = @import("std");
const print = std.debug.print;

const memory = @import("memory.zig");
const _struct = @import("struct.zig");

pub fn main() !void {
    const ns = [_]usize{ 10, 100, 500 };
    const its = 10;
    const runs = 10;

    print("Memory implementation\n", .{});
    for (ns) |n| {
        var total_time: f64 = 0;
        for (0..runs) |_| {
            const start = std.time.nanoTimestamp();
            memmory_implementation(n, n, its);
            const end = std.time.nanoTimestamp();
            const elapsed_ns = end - start;
            const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(std.time.ns_per_s));
            total_time += elapsed_s;
        }
        const its_per_s = runs / total_time;
        print("n: {}, its/s: {d:.4}\n", .{ n, its_per_s });
    }

    print("Struct implementation\n", .{});
    for (ns) |n| {
        var total_time: f64 = 0;
        for (0..runs) |_| {
            const start = std.time.nanoTimestamp();
            try struct_implementation(n, n, its);
            const end = std.time.nanoTimestamp();
            const elapsed_ns = end - start;
            const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(std.time.ns_per_s));
            total_time += elapsed_s;
        }
        const its_per_s = runs / total_time;
        print("n: {}, its/s: {d:.4}\n", .{ n, its_per_s });
    }
}

fn memmory_implementation(ny: usize, nx: usize, its: i32) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = memory.init_grid(allocator, ny, nx);
    defer memory.deinit_grid(allocator, grid);
    var updated_grid = memory.init_grid(allocator, ny, nx);
    defer memory.deinit_grid(allocator, updated_grid);

    var it: i32 = 0;
    while (it < its) : (it += 1) {
        memory.update_grid(&grid, &updated_grid);
    }
}

fn struct_implementation(ny: usize, nx: usize, its: i32) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try _struct.Grid.init(allocator, ny, nx);
    defer grid.deinit(allocator);
    var updated_grid = try _struct.Grid.init(allocator, ny, nx);
    defer updated_grid.deinit(allocator);

    var it: i32 = 0;
    while (it < its) : (it += 1) {
        _struct.update_grid(&grid, &updated_grid);
    }
}
