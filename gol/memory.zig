const std = @import("std");
const print = std.debug.print;
const sleep = std.Thread.sleep;

const NY: i32 = 30;
const NX: i32 = 50;
const NITS: i32 = 100;
const SLEEP_TIME: i32 = 100;

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = init_grid(allocator, NY, NX);
    defer deinit_grid(allocator, grid);

    print("grid.len: {}\n", .{grid.len});
    print("grid[0].len: {}\n", .{grid[0].len});

    // var it: i32 = 0;
    // while (it < NITS) : (it += 1) {
    //     const updated_grid = update_grid(grid);
    //     print_grid(updated_grid, it);
    //     grid = updated_grid;
    //     sleep(SLEEP_TIME * std.time.ns_per_ms);
    // }
}

// pub so I can import in tests
pub fn init_grid(allocator: std.mem.Allocator, ny: usize, nx: usize) [][]u8 {
    var grid = allocator.alloc([]u8, ny) catch unreachable;
    for (0..ny) |i| {
        grid[i] = allocator.alloc(u8, nx) catch unreachable;
        for (0..nx) |j| {
            grid[i][j] = std.crypto.random.int(u8) % 2;
        }
    }
    return grid;
}

pub fn deinit_grid(allocator: std.mem.Allocator, grid: [][]u8) void {
    for (grid) |row| {
        allocator.free(row);
    }
    allocator.free(grid);
}

pub fn update_grid(grid: [][]u8) [][]u8 {
    const ny = grid.len;
    const nx = grid[0].len;
    var new_grid: [ny][nx]u8 = undefined;
    for (0..ny) |i| {
        for (0..nx) |j| {
            const num_alive_neighbors = compute_alive_neighbors(grid, i, j);
            // apply the rules
            if (grid[i][j] == 1) {
                if (num_alive_neighbors < 2 or num_alive_neighbors > 3) {
                    new_grid[i][j] = 0;
                } else {
                    new_grid[i][j] = 1;
                }
            } else {
                if (num_alive_neighbors == 3) {
                    new_grid[i][j] = 1;
                } else {
                    new_grid[i][j] = 0;
                }
            }
        }
    }
    return new_grid;
}

fn compute_alive_neighbors(grid: [][]u8, i: usize, j: usize) u8 {
    const ny = grid.len;
    const nx = grid[0].len;
    var num_alive_neighbors: u8 = 0;
    // compute the number of alive neighbors
    if (i > 0) {
        if (j > 0) {
            num_alive_neighbors += grid[i - 1][j - 1];
        }
        if (j < nx - 1) {
            num_alive_neighbors += grid[i - 1][j + 1];
        }
        num_alive_neighbors += grid[i - 1][j];
    }
    if (i < ny - 1) {
        if (j > 0) {
            num_alive_neighbors += grid[i + 1][j - 1];
        }
        if (j < nx - 1) {
            num_alive_neighbors += grid[i + 1][j + 1];
        }
        num_alive_neighbors += grid[i + 1][j];
    }
    if (j > 0) {
        num_alive_neighbors += grid[i][j - 1];
    }
    if (j < nx - 1) {
        num_alive_neighbors += grid[i][j + 1];
    }
    return num_alive_neighbors;
}

fn print_grid(grid: [][]u8, it: i32) void {
    const ny = grid.len;
    const nx = grid[0].len;
    print("\nIteration {}\n", .{it});
    for (0..ny) |i| {
        for (0..nx) |j| {
            if (grid[i][j] == 1) {
                print("#", .{});
            } else {
                print(" ", .{});
            }
        }
        print("\n", .{});
    }
}
