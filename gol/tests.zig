const std = @import("std");
const expect = std.testing.expect;
const functions = @import("functions");

test "test_simulation" {
    const grid = functions.init_grid();
    const new_grid = functions.update_grid(grid);
    expect(new_grid == grid);
}
