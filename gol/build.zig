const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults.
    const target = b.standardTargetOptions(.{});

    // Create the memory module
    const memory_mod = b.addModule("memory", .{
        .root_source_file = b.path("memory.zig"),
        .target = target,
    });

    // Create the test module that imports memory
    const test_mod = b.addModule("test_module", .{
        .root_source_file = b.path("tests.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "memory", .module = memory_mod },
        },
    });

    // Create test step
    const test_step = b.step("test", "Run tests");
    const tests = b.addTest(.{
        .root_module = test_mod,
    });

    // Run the tests
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);
}
