const std = @import("std");
const print = std.debug.print;
const sleep = std.Thread.sleep;

const NX: i32 = 50;
const NY: i32 = 30;
const NITS: i32 = 200;
const SLEEP_TIME: i32 = 100;

pub fn main() void {
    // Initialize the grid
    var grid: [NY][NX]u8 = undefined;
    for (0..NY) |i| {
        for (0..NX) |j| {
            grid[i][j] = std.crypto.random.int(u8) % 2;
            // print("{},{}={}\n", .{ i, j, grid[i][j] });
        }
    }
    // Run the simulation
    var it: i32 = 0;
    var new_grid: [NY][NX]u8 = undefined;
    while (it < NITS) : (it += 1) {
        print("\nIteration {}\n", .{it});
        // compute the new grid
        for (0..NY) |i| {
            for (0..NX) |j| {
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
        // print the new grid in the console
        for (0..NY) |i| {
            for (0..NX) |j| {
                if (new_grid[i][j] == 1) {
                    print("#", .{});
                } else {
                    print(" ", .{});
                }
            }
            print("\n", .{});
        }
        grid = new_grid;
        // wait for the next frame
        sleep(SLEEP_TIME * std.time.ns_per_ms);
        // print("\x1b[H", .{}); // move cursor to home position (ANSI escape)

    }
}
