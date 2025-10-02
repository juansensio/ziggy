const std = @import("std");
const print = std.debug.print;

const memory = @import("memory.zig");

pub fn main() void {
    const ns = [_]usize{ 10, 100 };
    const its = 100;

    for (ns) |n| {
        const start = std.time.nanoTimestamp();
        memmory_implementation(n, n, its);
        const end = std.time.nanoTimestamp();
        const elapsed_ns = end - start;
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
