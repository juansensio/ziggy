const std = @import("std");
const print = std.debug.print;
const sleep = std.Thread.sleep;

const NY: i32 = 30;
const NX: i32 = 50;
const NITS: i32 = 100;
const SLEEP_TIME: i32 = 100;

// zig has vector type, but need to know size at compile time and does not work for large arrays

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var gol = try GOL.init(allocator, NY, NX);
    defer gol.deinit();
    try gol.update(NITS, true);
}

pub const GOL = struct {
    grid: []u8,
    updated_grid: []u8,
    neighbors: [][]u8,
    alive_neighbors: []u8,
    allocator: std.mem.Allocator,
    ny: usize,
    nx: usize,

    pub fn init(allocator: std.mem.Allocator, ny: usize, nx: usize) !GOL {
        return GOL{
            .grid = init_grid(allocator, ny, nx),
            .updated_grid = init_grid(allocator, ny, nx),
            .neighbors = init_neighbors(allocator, ny, nx),
            .alive_neighbors = init_alive_neighbors(allocator, ny, nx),
            .allocator = allocator,
            .ny = ny,
            .nx = nx,
        };
    }

    pub fn deinit(self: *GOL) void {
        deinit_grid(self.allocator, self.grid);
        deinit_grid(self.allocator, self.updated_grid);
        deinit_neighbors(self.allocator, self.neighbors);
        deinit_alive_neighbors(self.allocator, self.alive_neighbors);
    }

    pub fn update(self: *GOL, its: i32, show_grid: bool) !void {
        var it: i32 = 0;
        while (it < its) : (it += 1) {
            update_grid(&self.grid, &self.updated_grid, &self.neighbors, &self.alive_neighbors, self.ny, self.nx);
            if (show_grid) {
                print_grid(self.grid, self.ny, self.nx, it);
                sleep(SLEEP_TIME * std.time.ns_per_ms);
            }
        }
    }
};

fn matrix_implementation(ny: usize, nx: usize, its: i32, show_grid: bool) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid: []u8 = init_grid(allocator, ny, nx);
    defer deinit_grid(allocator, grid);
    // print_grid(grid, ny, nx, 0);
    var updated_grid: []u8 = init_grid(allocator, ny, nx);
    defer deinit_grid(allocator, updated_grid);
    const neighbors: [][]u8 = init_neighbors(allocator, ny, nx);
    defer deinit_neighbors(allocator, neighbors);
    var alive_neighbors: []u8 = init_alive_neighbors(allocator, ny, nx);
    defer deinit_alive_neighbors(allocator, alive_neighbors);

    // print neighbors
    // for (0..(ny + 2)) |i| {
    //     for (0..(nx + 2)) |j| {
    //         print("{},{}: ", .{ i, j });
    //         for (0..(ny + 2) * (nx + 2)) |k| {
    //             print("{} ", .{neighbors[i * (nx + 2) + j][k]});
    //         }
    //         print("\n", .{});
    //     }
    // }

    var it: i32 = 0;
    while (it < its) : (it += 1) {
        update_grid(&grid, &updated_grid, &neighbors, &alive_neighbors, ny, nx);
        if (show_grid) {
            print_grid(grid, ny, nx, it + 1);
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

fn init_neighbors(allocator: std.mem.Allocator, ny: usize, nx: usize) [][]u8 {
    // allocate the neighbors array
    var neighbors = allocator.alloc([]u8, (ny + 2) * (nx + 2)) catch unreachable;
    for (0..(ny + 2) * (nx + 2)) |i| {
        neighbors[i] = allocator.alloc(u8, (ny + 2) * (nx + 2)) catch unreachable;
    }
    // initialize the neighbors array to 0
    for (0..(ny + 2) * (nx + 2)) |i| {
        for (0..(ny + 2) * (nx + 2)) |j| {
            neighbors[i][j] = 0;
        }
    }
    // set the neighbors array to 1 for the neighbors of each cell in the grid
    for (1..ny + 1) |i| {
        for (1..nx + 1) |j| {
            const grid_id = i * (nx + 2) + j;
            neighbors[grid_id][grid_id - 1] = 1;
            neighbors[grid_id][grid_id + 1] = 1;
            neighbors[grid_id][grid_id - (nx + 2)] = 1;
            neighbors[grid_id][grid_id + (nx + 2)] = 1;
            neighbors[grid_id][grid_id - (nx + 2) - 1] = 1;
            neighbors[grid_id][grid_id - (nx + 2) + 1] = 1;
            neighbors[grid_id][grid_id + (nx + 2) - 1] = 1;
            neighbors[grid_id][grid_id + (nx + 2) + 1] = 1;
        }
    }
    return neighbors;
}

fn deinit_neighbors(allocator: std.mem.Allocator, neighbors: [][]u8) void {
    for (neighbors) |row| {
        allocator.free(row);
    }
    allocator.free(neighbors);
}

fn init_alive_neighbors(allocator: std.mem.Allocator, ny: usize, nx: usize) []u8 {
    var alive_neighbors = allocator.alloc(u8, (ny + 2) * (nx + 2)) catch unreachable;
    for (0..(ny + 2) * (nx + 2)) |i| {
        alive_neighbors[i] = 0;
    }
    return alive_neighbors;
}

fn deinit_alive_neighbors(allocator: std.mem.Allocator, alive_neighbors: []u8) void {
    allocator.free(alive_neighbors);
}

fn update_grid(grid: *[]u8, new_grid: *[]u8, neighbors: *const [][]u8, alive_neighbors: *[]u8, ny: usize, nx: usize) void {
    // reset alive neighbors
    for (0..(ny + 2) * (nx + 2)) |i| {
        alive_neighbors.*[i] = 0;
    }
    // matrix - vector multiplication
    for (0..(ny + 2) * (nx + 2)) |i| {
        for (0..(ny + 2) * (nx + 2)) |j| {
            alive_neighbors.*[i] += neighbors.*[i][j] * grid.*[j];
        }
    }
    // for (1..ny + 1) |i| {
    //     for (1..nx + 1) |j| {
    //         print("{}", .{grid.*[i * (nx + 2) + j]});
    //     }
    //     print("\n", .{});
    // }
    // for (1..ny + 1) |i| {
    //     for (1..nx + 1) |j| {
    //         print("{}", .{alive_neighbors.*[i * (nx + 2) + j]});
    //     }
    //     print("\n", .{});
    // }
    // apply the rules
    for (1..ny + 1) |i| {
        for (1..nx + 1) |j| {
            if (grid.*[i * (nx + 2) + j] == 1) {
                if (alive_neighbors.*[i * (nx + 2) + j] < 2 or alive_neighbors.*[i * (nx + 2) + j] > 3) {
                    new_grid.*[i * (nx + 2) + j] = 0;
                } else {
                    new_grid.*[i * (nx + 2) + j] = 1;
                }
            } else {
                if (alive_neighbors.*[i * (nx + 2) + j] == 3) {
                    new_grid.*[i * (nx + 2) + j] = 1;
                } else {
                    new_grid.*[i * (nx + 2) + j] = 0;
                }
            }
        }
    }
    // update the grid
    for (1..ny + 1) |i| {
        for (1..nx + 1) |j| {
            grid.*[i * (nx + 2) + j] = new_grid.*[i * (nx + 2) + j];
        }
    }
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
