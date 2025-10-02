const std = @import("std");

pub const Grid = struct {
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
