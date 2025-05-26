const std = @import("std");

pub fn build(b: *std.Build) void {
    // ─────────────────────────────────────────────────────────────
    // 1. Resolve the effective target once.
    // ─────────────────────────────────────────────────────────────
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ─────────────────────────────────────────────────────────────
    // 2. Zig source modules
    // ─────────────────────────────────────────────────────────────
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ─────────────────────────────────────────────────────────────
    // 3. Static library that exposes the Zig API
    // ─────────────────────────────────────────────────────────────
    const lib = b.addLibrary(.{
        .name = "zighash",
        .linkage = .static,
        .root_module = lib_mod,
    });
    lib.addIncludePath(b.path("include/"));
    b.installArtifact(lib);

    // ─────────────────────────────────────────────────────────────
    // 4. Unit tests
    // ─────────────────────────────────────────────────────────────
    const hash_tests = b.addTest(.{
        .root_source_file = b.path("src/zighash.zig"),
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(hash_tests).step);
}
