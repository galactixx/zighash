const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/zighash.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("zighash_lib", lib_mod);
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "zighash",
        .root_module = lib_mod,
    });

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "zighash",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // ─────────────────────────────────────────────────────────────
    // 5. Unit tests
    // ─────────────────────────────────────────────────────────────
    const hash_tests = b.addTest(.{
        .root_source_file = b.path("src/zighash.zig"),
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(hash_tests).step);
}
