const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

const memory = @import("memory.zig");
const _struct = @import("struct.zig");
const matrix = @import("matrix.zig");
const sparse = @import("sparse.zig");

test "test_memory_update_grid" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ny = 5;
    const nx = 5;
    var gol = try memory.GOL.init(allocator, ny, nx);
    defer gol.deinit();

    // Initialize grid with a "blinker" pattern (vertical in the center)
    // 0 0 0 0 0
    // 0 0 1 0 0
    // 0 0 1 0 0
    // 0 0 1 0 0
    // 0 0 0 0 0
    for (0..ny) |i| {
        for (0..nx) |j| {
            gol.grid[i][j] = 0;
        }
    }
    gol.grid[1][2] = 1;
    gol.grid[2][2] = 1;
    gol.grid[3][2] = 1;

    // Update grid
    try gol.update(1, false);

    // Check if the grid has updated correctly
    try expect(gol.grid[1][2] == 0);
    try expect(gol.grid[2][2] == 1);
    try expect(gol.grid[3][2] == 0);
}

test "test_struct_update_grid" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ny = 5;
    const nx = 5;
    var gol = try _struct.GOL.init(allocator, ny, nx);
    defer gol.deinit();

    // Initialize grid with a "blinker" pattern (vertical in the center)
    // 0 0 0 0 0
    // 0 0 1 0 0
    // 0 0 1 0 0
    // 0 0 1 0 0
    // 0 0 0 0 0
    for (0..ny) |i| {
        for (0..nx) |j| {
            gol.grid.set(i, j, 0);
        }
    }
    gol.grid.set(1, 2, 1);
    gol.grid.set(2, 2, 1);
    gol.grid.set(3, 2, 1);

    // Update grid
    try gol.update(1, false);

    // Check if the grid has updated correctly
    try expect(gol.grid.get(1, 2) == 0);
    try expect(gol.grid.get(2, 2) == 1);
    try expect(gol.grid.get(3, 2) == 0);
}

test "test_matrix_update_grid" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ny = 5;
    const nx = 5;
    var gol = try matrix.GOL.init(allocator, ny, nx);
    defer gol.deinit();

    // Initialize grid with a "blinker" pattern (vertical in the center)
    // 0 0 0 0 0
    // 0 0 1 0 0
    // 0 0 1 0 0
    // 0 0 1 0 0
    // 0 0 0 0 0
    for (0..ny) |i| {
        for (0..nx) |j| {
            gol.grid[i * (nx + 2) + j] = 0;
        }
    }
    gol.grid[1 * (nx + 2) + 2] = 1;
    gol.grid[2 * (nx + 2) + 2] = 1;
    gol.grid[3 * (nx + 2) + 2] = 1;

    // Update grid
    try gol.update(1, false);

    // Check if the grid has updated correctly
    try expect(gol.grid[1 * (nx + 2) + 2] == 0);
    try expect(gol.grid[2 * (nx + 2) + 2] == 1);
    try expect(gol.grid[3 * (nx + 2) + 2] == 0);
}

test "test_sparse_matrix" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a sparse matrix
    var smatrix = try sparse.SparseMatrix.init(allocator, 4, 4);
    defer smatrix.deinit();

    // Add some elements
    try smatrix.addElement(0, 0, 1.0);
    try smatrix.addElement(0, 1, 2.0);
    try smatrix.addElement(1, 1, 3.0);
    try smatrix.addElement(2, 2, 4.0);
    try smatrix.addElement(3, 3, 5.0);

    // smatrix.print();
    // smatrix.printDense();

    // Test smatrix-vector multiplication
    const vector = [_]u8{ 1.0, 2.0, 3.0, 4.0 };
    const result = try allocator.alloc(u8, 4);
    defer allocator.free(result);

    try smatrix.matrixVectorMultiply(@constCast(&vector), result);

    // Assert the expected results
    try expect(result[0] == 1.0 * 1.0 + 2.0 * 2.0);
    try expect(result[1] == 3.0 * 2.0);
    try expect(result[2] == 4.0 * 3.0);
    try expect(result[3] == 5.0 * 4.0);
}

test "test_sparse_update_grid" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ny = 5;
    const nx = 5;
    var gol = try sparse.GOL.init(allocator, ny, nx);
    defer gol.deinit();

    // Initialize grid with a "blinker" pattern (vertical in the center)
    for (0..ny) |i| {
        for (0..nx) |j| {
            gol.grid[i * (nx + 2) + j] = 0;
        }
    }
    gol.grid[1 * (nx + 2) + 2] = 1;
    gol.grid[2 * (nx + 2) + 2] = 1;
    gol.grid[3 * (nx + 2) + 2] = 1;

    // Update grid
    try gol.update(1, false);

    // Check if the grid has updated correctly
    try expect(gol.grid[1 * (nx + 2) + 2] == 0);
    try expect(gol.grid[2 * (nx + 2) + 2] == 1);
    try expect(gol.grid[3 * (nx + 2) + 2] == 0);
}
