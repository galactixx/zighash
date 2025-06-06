const std = @import("std");

pub fn build(b: *std.Build) void {
    const root_source_file = "src/lib.zig";

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zh_mod = b.addModule("zighash", .{
        .root_source_file = b.path(root_source_file),
        .target = target,
        .optimize = optimize,
    });

    _ = b.addLibrary(.{
        .name = "zighash",
        .linkage = .static,
        .root_module = zh_mod,
    });

    const unit_tests = b.addTest(.{
        .root_source_file = b.path(root_source_file),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
