const std = @import("std");
const expect = std.testing.expect;

const memory = @import("memory");

test "test_memory_init_grid" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ny = 30;
    const nx = 50;
    const grid = memory.init_grid(allocator, ny, nx);
    defer memory.deinit_grid(allocator, grid); // Don't forget to clean up!

    try expect(grid.len == ny);
    try expect(grid[0].len == nx);
}

test "test_memory_update_grid" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ny = 5;
    const nx = 5;
    const grid = memory.init_grid(allocator, ny, nx);
    defer memory.deinit_grid(allocator, grid);

    // Initialize grid with a "blinker" pattern (vertical in the center)
    // 0 0 0 0 0
    // 0 0 1 0 0
    // 0 0 1 0 0
    // 0 0 1 0 0
    // 0 0 0 0 0
    for (0..ny) |i| {
        for (0..nx) |j| {
            grid[i][j] = 0;
        }
    }
    grid[1][2] = 1;
    grid[2][2] = 1;
    grid[3][2] = 1;

    // Update grid
    const updated_grid = memory.update_grid(grid);
    defer memory.deinit_grid(allocator, updated_grid);

    // Check if the grid has updated correctly
    try expect(updated_grid[1][2] == 0);
    try expect(updated_grid[2][2] == 1);
    try expect(updated_grid[3][2] == 0);
}
