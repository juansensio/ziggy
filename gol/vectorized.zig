const std = @import("std");
const print = std.debug.print;
const sleep = std.Thread.sleep;

const NY: i32 = 30;
const NX: i32 = 50;
const NITS: i32 = 100;
const SLEEP_TIME: i32 = 100;

// zig has vector type, but need to know size at compile time and does not work for large arrays

pub fn main() !void {
    try vectorized_implementation(NY, NX, NITS, true);
}

pub fn vectorized_implementation(ny: usize, nx: usize, its: i32, show_grid: bool) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid: []u8 = init_grid(allocator, ny, nx);
    defer deinit_grid(allocator, grid);
    var updated_grid: []u8 = init_grid(allocator, ny, nx);
    defer deinit_grid(allocator, updated_grid);

    var it: i32 = 0;
    while (it < its) : (it += 1) {
        update_grid(&grid, &updated_grid, ny, nx);
        if (show_grid) {
            print_grid(grid, ny, nx, it);
            sleep(SLEEP_TIME * std.time.ns_per_ms);
        }
    }
}

fn init_grid(allocator: std.mem.Allocator, ny: usize, nx: usize) []u8 {
    var grid = allocator.alloc(u8, (ny + 2) * (nx + 2)) catch unreachable;
    for (0..ny + 2) |i| {
        for (0..nx + 2) |j| {
            grid[i * (nx + 2) + j] = std.crypto.random.int(u8) % 2;
        }
    }
    return grid;
}

fn deinit_grid(allocator: std.mem.Allocator, grid: []u8) void {
    allocator.free(grid);
}

fn update_grid(grid: *[]u8, new_grid: *[]u8, ny: usize, nx: usize) void {
    for (1..ny + 1) |i| {
        for (1..nx + 1) |j| {
            const num_alive_neighbors = compute_alive_neighbors(grid.*, i, j, nx);
            if (grid.*[i * (nx + 2) + j] == 1) {
                if (num_alive_neighbors < 2 or num_alive_neighbors > 3) {
                    new_grid.*[i * (nx + 2) + j] = 0;
                } else {
                    new_grid.*[i * (nx + 2) + j] = 1;
                }
            } else {
                if (num_alive_neighbors == 3) {
                    new_grid.*[i * (nx + 2) + j] = 1;
                } else {
                    new_grid.*[i * (nx + 2) + j] = 0;
                }
            }
        }
    }
    for (1..ny + 1) |i| {
        for (1..nx + 1) |j| {
            grid.*[i * (nx + 2) + j] = new_grid.*[i * (nx + 2) + j];
        }
    }
}

// TODO: convert to matrix multiplication
fn compute_alive_neighbors(grid: []u8, i: usize, j: usize, nx: usize) u8 {
    var num_alive_neighbors: u8 = 0;
    num_alive_neighbors += grid[(i - 1) * (nx + 2) + j];
    num_alive_neighbors += grid[(i + 1) * (nx + 2) + j];
    num_alive_neighbors += grid[i * (nx + 2) + j - 1];
    num_alive_neighbors += grid[i * (nx + 2) + j + 1];
    num_alive_neighbors += grid[(i - 1) * (nx + 2) + j - 1];
    num_alive_neighbors += grid[(i - 1) * (nx + 2) + j + 1];
    num_alive_neighbors += grid[(i + 1) * (nx + 2) + j - 1];
    num_alive_neighbors += grid[(i + 1) * (nx + 2) + j + 1];
    return num_alive_neighbors;
}

fn print_grid(grid: []u8, ny: usize, nx: usize, it: i32) void {
    print("\nIteration {}\n", .{it});
    for (1..ny + 1) |i| {
        for (1..nx + 1) |j| {
            if (grid[i * (nx + 2) + j] == 1) {
                print("#", .{});
            } else {
                print(" ", .{});
            }
        }
        print("\n", .{});
    }
}
