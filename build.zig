const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.Build) void {
    const mode = b.option(std.builtin.Mode, "mode", "") orelse .Debug;
    const target = b.standardTargetOptions(.{});
    const disable_llvm = b.option(bool, "disable_llvm", "use the non-llvm zig codegen") orelse false;

    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = mode,
    });
    deps.addAllTo(lib_tests);
    lib_tests.use_llvm = !disable_llvm;
    lib_tests.use_lld = !disable_llvm;

    const tests = b.step("test", "Run all library tests");
    const tests_run = b.addRunArtifact(lib_tests);
    tests.dependOn(&tests_run.step);
}
