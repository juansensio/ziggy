const std = @import("std");
const print = std.debug.print;
const sleep = std.Thread.sleep;

const NY: i32 = 20;
const NX: i32 = 20;
const NITS: i32 = 10;
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
    neighbors: SparseMatrix,
    alive_neighbors: []u8,
    allocator: std.mem.Allocator,
    ny: usize,
    nx: usize,

    pub fn init(allocator: std.mem.Allocator, ny: usize, nx: usize) !GOL {
        return GOL{
            .grid = init_grid(allocator, ny, nx),
            .updated_grid = init_grid(allocator, ny, nx),
            .neighbors = try init_neighbors(allocator, ny, nx),
            .alive_neighbors = init_alive_neighbors(allocator, ny, nx),
            .allocator = allocator,
            .ny = ny,
            .nx = nx,
        };
    }

    pub fn deinit(self: *GOL) void {
        deinit_grid(self.allocator, self.grid);
        deinit_grid(self.allocator, self.updated_grid);
        self.neighbors.deinit();
        deinit_alive_neighbors(self.allocator, self.alive_neighbors);
    }

    pub fn update(self: *GOL, its: i32, show_grid: bool) !void {
        var it: i32 = 0;
        while (it < its) : (it += 1) {
            try update_grid(&self.grid, &self.updated_grid, &self.neighbors, &self.alive_neighbors, self.ny, self.nx);
            if (show_grid) {
                print_grid(self.grid, self.ny, self.nx, it);
                sleep(SLEEP_TIME * std.time.ns_per_ms);
            }
        }
    }
};

pub const SparseMatrix = struct {
    rows: []usize,
    cols: []usize,
    vals: []u8,
    nnz: usize, // number of non-zero elements
    height: usize,
    width: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, height: usize, width: usize) !SparseMatrix {
        return SparseMatrix{
            .rows = try allocator.alloc(usize, 0),
            .cols = try allocator.alloc(usize, 0),
            .vals = try allocator.alloc(u8, 0),
            .nnz = 0,
            .height = height,
            .width = width,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SparseMatrix) void {
        self.allocator.free(self.rows);
        self.allocator.free(self.cols);
        self.allocator.free(self.vals);
    }

    pub fn addElement(self: *SparseMatrix, row: usize, col: usize, val: u8) !void {
        if (row >= self.height or col >= self.width) {
            return error.IndexOutOfBounds;
        }
        if (val == 0.0) return; // don't store zero values

        // Check if element already exists
        for (0..self.nnz) |i| {
            if (self.rows[i] == row and self.cols[i] == col) {
                self.vals[i] = val;
                return;
            }
        }

        // Add new element
        self.rows = try self.allocator.realloc(self.rows, self.nnz + 1);
        self.cols = try self.allocator.realloc(self.cols, self.nnz + 1);
        self.vals = try self.allocator.realloc(self.vals, self.nnz + 1);

        self.rows[self.nnz] = row;
        self.cols[self.nnz] = col;
        self.vals[self.nnz] = val;
        self.nnz += 1;
    }

    pub fn getElement(self: *const SparseMatrix, row: usize, col: usize) u8 {
        if (row >= self.height or col >= self.width) return 0;

        for (0..self.nnz) |i| {
            if (self.rows[i] == row and self.cols[i] == col) {
                return self.vals[i];
            }
        }
        return 0;
    }

    pub fn removeElement(self: *SparseMatrix, row: usize, col: usize) void {
        for (0..self.nnz) |i| {
            if (self.rows[i] == row and self.cols[i] == col) {
                // Move last element to this position
                if (self.nnz > 1 and i < self.nnz - 1) {
                    self.rows[i] = self.rows[self.nnz - 1];
                    self.cols[i] = self.cols[self.nnz - 1];
                    self.vals[i] = self.vals[self.nnz - 1];
                }
                self.nnz -= 1;
                break;
            }
        }
    }

    pub fn matrixVectorMultiply(self: *const SparseMatrix, vector: []u8, result: []u8) !void {
        if (vector.len != self.width or result.len != self.height) {
            return error.InvalidDimensions;
        }

        // Initialize result to zero
        for (0..result.len) |i| {
            result[i] = 0;
        }

        // Perform sparse matrix-vector multiplication
        for (0..self.nnz) |i| {
            const row = self.rows[i];
            const col = self.cols[i];
            const val = self.vals[i];
            result[row] += val * vector[col];
        }
    }

    pub fn print(self: *const SparseMatrix) void {
        std.debug.print("SparseMatrix {}x{} with {} non-zero elements:\n", .{ self.height, self.width, self.nnz });
        for (0..self.nnz) |i| {
            std.debug.print("  ({}, {}) = {}\n", .{ self.rows[i], self.cols[i], self.vals[i] });
        }
    }

    pub fn printDense(self: *const SparseMatrix) void {
        std.debug.print("Dense representation:\n", .{});
        for (0..self.height) |i| {
            for (0..self.width) |j| {
                std.debug.print("{:8.3} ", .{self.getElement(i, j)});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn fromDense(allocator: std.mem.Allocator, dense: []const []const u8) !SparseMatrix {
        const height = dense.len;
        const width = if (height > 0) dense[0].len else 0;
        var matrix = try SparseMatrix.init(allocator, height, width);

        for (0..height) |i| {
            for (0..width) |j| {
                if (dense[i][j] != 0) {
                    try matrix.addElement(i, j, dense[i][j]);
                }
            }
        }

        return matrix;
    }
};

fn init_grid(allocator: std.mem.Allocator, ny: usize, nx: usize) []u8 {
    var grid = allocator.alloc(u8, (ny + 2) * (nx + 2)) catch unreachable;
    for (0..ny + 2) |i| {
        for (0..nx + 2) |j| {
            grid[i * (nx + 2) + j] = @import("std").crypto.random.int(u8) % 2;
        }
    }
    return grid;
}

fn deinit_grid(allocator: std.mem.Allocator, grid: []u8) void {
    allocator.free(grid);
}

fn init_neighbors(allocator: std.mem.Allocator, ny: usize, nx: usize) !SparseMatrix {
    var neighbors = try SparseMatrix.init(allocator, (ny + 2) * (nx + 2), (ny + 2) * (nx + 2));
    for (1..ny + 1) |i| {
        for (1..nx + 1) |j| {
            const grid_id = i * (nx + 2) + j;
            try neighbors.addElement(grid_id, grid_id - 1, 1);
            try neighbors.addElement(grid_id, grid_id + 1, 1);
            try neighbors.addElement(grid_id, grid_id - (nx + 2), 1);
            try neighbors.addElement(grid_id, grid_id + (nx + 2), 1);
            try neighbors.addElement(grid_id, grid_id - (nx + 2) - 1, 1);
            try neighbors.addElement(grid_id, grid_id - (nx + 2) + 1, 1);
            try neighbors.addElement(grid_id, grid_id + (nx + 2) - 1, 1);
            try neighbors.addElement(grid_id, grid_id + (nx + 2) + 1, 1);
        }
    }
    return neighbors;
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

fn update_grid(grid: *[]u8, new_grid: *[]u8, neighbors: *SparseMatrix, alive_neighbors: *[]u8, ny: usize, nx: usize) !void {
    // matrix - vector multiplication
    try neighbors.matrixVectorMultiply(grid.*, alive_neighbors.*);
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
