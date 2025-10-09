const std = @import("std");
const print = std.debug.print;
const sleep = std.Thread.sleep;

const NY: i32 = 30;
const NX: i32 = 50;
const NITS: i32 = 100;
const SLEEP_TIME: i32 = 100;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var gol = try GOL.init(allocator, NY, NX);
    defer gol.deinit();
    try gol.update(NITS, true);
}

pub const GOL = struct {
    grid: [][]u8,
    updated_grid: [][]u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, ny: usize, nx: usize) !GOL {
        return GOL{ .grid = init_grid(allocator, ny, nx), .updated_grid = init_grid(allocator, ny, nx), .allocator = allocator };
    }

    pub fn deinit(self: *GOL) void {
        deinit_grid(self.allocator, self.grid);
        deinit_grid(self.allocator, self.updated_grid);
    }

    pub fn update(self: *GOL, its: i32, show_grid: bool) !void {
        var it: i32 = 0;
        while (it < its) : (it += 1) {
            update_grid(&self.grid, &self.updated_grid);
            if (show_grid) {
                print_grid(self.grid, it);
                sleep(SLEEP_TIME * std.time.ns_per_ms);
            }
        }
    }
};

fn init_grid(allocator: std.mem.Allocator, ny: usize, nx: usize) [][]u8 {
    var grid = allocator.alloc([]u8, ny) catch unreachable;
    for (0..ny) |i| {
        grid[i] = allocator.alloc(u8, nx) catch unreachable;
        for (0..nx) |j| {
            grid[i][j] = std.crypto.random.int(u8) % 2;
        }
    }
    return grid;
}

fn deinit_grid(allocator: std.mem.Allocator, grid: [][]u8) void {
    for (grid) |row| {
        allocator.free(row);
    }
    allocator.free(grid);
}

fn update_grid(grid: *[][]u8, new_grid: *[][]u8) void {
    const ny = grid.*.len;
    const nx = grid.*[0].len;
    for (0..ny) |i| {
        for (0..nx) |j| {
            const num_alive_neighbors = compute_alive_neighbors(grid.*, i, j);
            // apply the rules
            if (grid.*[i][j] == 1) {
                if (num_alive_neighbors < 2 or num_alive_neighbors > 3) {
                    new_grid.*[i][j] = 0;
                } else {
                    new_grid.*[i][j] = 1;
                }
            } else {
                if (num_alive_neighbors == 3) {
                    new_grid.*[i][j] = 1;
                } else {
                    new_grid.*[i][j] = 0;
                }
            }
        }
    }
    for (0..ny) |i| {
        for (0..nx) |j| {
            grid.*[i][j] = new_grid.*[i][j];
        }
    }
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
