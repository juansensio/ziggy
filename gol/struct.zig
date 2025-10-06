const std = @import("std");
const print = std.debug.print;
const sleep = std.Thread.sleep;

const NY: i32 = 30;
const NX: i32 = 50;
const NITS: i32 = 100;
const SLEEP_TIME: i32 = 100;
pub fn main() !void {
    try struct_implementation(NY, NX, NITS, true);
}

pub fn struct_implementation(ny: usize, nx: usize, its: i32, show_grid: bool) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try Grid.init(allocator, ny, nx);
    defer grid.deinit(allocator);
    var updated_grid = try Grid.init(allocator, ny, nx);
    defer updated_grid.deinit(allocator);

    var it: i32 = 0;
    while (it < its) : (it += 1) {
        update_grid(&grid, &updated_grid);
        // defer deinit_grid(allocator, updated_grid); // if deinit then grid segfaults
        if (show_grid) {
            print_grid(grid, it);
            sleep(SLEEP_TIME * std.time.ns_per_ms);
        }
    }
}

const Grid = struct {
    data: []u8,
    ny: usize,
    nx: usize,

    pub fn init(allocator: std.mem.Allocator, ny: usize, nx: usize) !Grid {
        const data = try allocator.alloc(u8, ny * nx);
        // Initialize with random values
        for (data) |*cell| {
            cell.* = std.crypto.random.int(u8) % 2;
        }
        return Grid{ .data = data, .ny = ny, .nx = nx };
    }

    pub fn deinit(self: *Grid, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn get(self: Grid, i: usize, j: usize) u8 {
        return self.data[i * self.nx + j];
    }

    pub fn set(self: *Grid, i: usize, j: usize, value: u8) void {
        self.data[i * self.nx + j] = value;
    }
};

fn update_grid(grid: *Grid, new_grid: *Grid) void {
    for (0..grid.ny) |i| {
        for (0..grid.nx) |j| {
            const num_alive_neighbors = compute_alive_neighbors(grid.*, i, j);
            // apply the rules
            if (grid.get(i, j) == 1) {
                if (num_alive_neighbors < 2 or num_alive_neighbors > 3) {
                    new_grid.set(i, j, 0);
                } else {
                    new_grid.set(i, j, 1);
                }
            } else {
                if (num_alive_neighbors == 3) {
                    new_grid.set(i, j, 1);
                } else {
                    new_grid.set(i, j, 0);
                }
            }
        }
    }
    for (0..grid.ny) |i| {
        for (0..grid.nx) |j| {
            grid.set(i, j, new_grid.get(i, j));
        }
    }
}

fn compute_alive_neighbors(grid: Grid, i: usize, j: usize) u8 {
    const ny = grid.ny;
    const nx = grid.nx;
    var num_alive_neighbors: u8 = 0;
    // compute the number of alive neighbors
    if (i > 0) {
        if (j > 0) {
            num_alive_neighbors += grid.get(i - 1, j - 1);
        }
        if (j < nx - 1) {
            num_alive_neighbors += grid.get(i - 1, j + 1);
        }
        num_alive_neighbors += grid.get(i - 1, j);
    }
    if (i < ny - 1) {
        if (j > 0) {
            num_alive_neighbors += grid.get(i + 1, j - 1);
        }
        if (j < nx - 1) {
            num_alive_neighbors += grid.get(i + 1, j + 1);
        }
        num_alive_neighbors += grid.get(i + 1, j);
    }
    if (j > 0) {
        num_alive_neighbors += grid.get(i, j - 1);
    }
    if (j < nx - 1) {
        num_alive_neighbors += grid.get(i, j + 1);
    }
    return num_alive_neighbors;
}

fn print_grid(grid: Grid, it: i32) void {
    print("\nIteration {}\n", .{it});
    for (0..grid.ny) |i| {
        for (0..grid.nx) |j| {
            if (grid.get(i, j) == 1) {
                print("#", .{});
            } else {
                print(" ", .{});
            }
        }
        print("\n", .{});
    }
}
