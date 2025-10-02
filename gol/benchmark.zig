const std = @import("std");
const print = std.debug.print;

const memory = @import("memory.zig");
const _struct = @import("struct.zig");

pub fn main() !void {
    const ns = [_]usize{ 10, 100 };
    const its = 100;

    for (ns) |n| {
        var start = std.time.nanoTimestamp();
        memmory_implementation(n, n, its);
        var end = std.time.nanoTimestamp();
        var elapsed_ns = end - start;
        print("Memory implementation\n", .{});
        print("n: {}, its: {}, time: {} ns\n", .{ n, its, elapsed_ns });
        start = std.time.nanoTimestamp();
        try struct_implementation(n, n, its);
        end = std.time.nanoTimestamp();
        elapsed_ns = end - start;
        print("Struct implementation\n", .{});
        print("n: {}, its: {}, time: {} ns\n", .{ n, its, elapsed_ns });
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
