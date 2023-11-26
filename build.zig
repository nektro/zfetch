const std = @import("std");
const packages = @import("./deps.zig");

pub fn build(b: *std.build.Builder) void {
    const mode = b.option(std.builtin.Mode, "mode", "") orelse .Debug;
    const target = b.standardTargetOptions(.{});

    const lib_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });
    const moddep_deps = packages.packages[0].zp(b).module.dependencies;
    for (moddep_deps.keys(), moddep_deps.values()) |name, module| {
        lib_tests.addModule(name, module);
    }

    const tests = b.step("test", "Run all library tests");
    const tests_run = b.addRunArtifact(lib_tests);
    tests.dependOn(&tests_run.step);
}
