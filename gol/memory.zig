const std = @import("std");
const print = std.debug.print;
const sleep = std.Thread.sleep;

const NY: i32 = 30;
const NX: i32 = 50;
const NITS: i32 = 100;
const SLEEP_TIME: i32 = 100;

pub fn main() void {
    var grid = init_grid();
    var it: i32 = 0;
    while (it < NITS) : (it += 1) {
        const new_grid = update_grid(grid);
        print_grid(new_grid, it);
        grid = new_grid;
        sleep(SLEEP_TIME * std.time.ns_per_ms);
    }
}

// I would like to be able to pass the grid size as an argument so I can test the function with different grid sizes
fn init_grid() [NY][NX]u8 {
    var grid: [NY][NX]u8 = undefined;
    for (0..NY) |i| {
        for (0..NX) |j| {
            grid[i][j] = std.crypto.random.int(u8) % 2;
            // print("{},{}={}\n", .{ i, j, grid[i][j] });
        }
    }
    return grid;
}

fn update_grid(grid: [NY][NX]u8) [NY][NX]u8 {
    var new_grid: [NY][NX]u8 = undefined;
    for (0..NY) |i| {
        for (0..NX) |j| {
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

fn compute_alive_neighbors(grid: [NY][NX]u8, i: usize, j: usize) u8 {
    var num_alive_neighbors: u8 = 0;
    // compute the number of alive neighbors
    if (i > 0) {
        if (j > 0) {
            num_alive_neighbors += grid[i - 1][j - 1];
        }
        if (j < NX - 1) {
            num_alive_neighbors += grid[i - 1][j + 1];
        }
        num_alive_neighbors += grid[i - 1][j];
    }
    if (i < NY - 1) {
        if (j > 0) {
            num_alive_neighbors += grid[i + 1][j - 1];
        }
        if (j < NX - 1) {
            num_alive_neighbors += grid[i + 1][j + 1];
        }
    }
    if (j > 0) {
        num_alive_neighbors += grid[i][j - 1];
    }
    if (j < NX - 1) {
        num_alive_neighbors += grid[i][j + 1];
    }
    return num_alive_neighbors;
}

fn print_grid(grid: [NY][NX]u8, it: i32) void {
    print("\nIteration {}\n", .{it});
    for (0..NY) |i| {
        for (0..NX) |j| {
            if (grid[i][j] == 1) {
                print("#", .{});
            } else {
                print(" ", .{});
            }
        }
        print("\n", .{});
    }
}
