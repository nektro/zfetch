const std = @import("std");

const Builder = std.build.Builder;

const packages = @import("deps.zig");

pub fn build(b: *Builder) void {
    const mode = b.option(std.builtin.Mode, "mode", "") orelse .Debug;
    const target = b.standardTargetOptions(.{});

    const lib_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    if (@hasDecl(packages, "use_submodules")) { // submodules
        const package = getPackage(b) catch unreachable;

        for (package.module.dependencies.keys(), package.module.dependencies.values()) |name, module| {
            lib_tests.addModule(name, module);
        }
    } else if (@hasDecl(packages, "addAllTo")) { // zigmod
        packages.addAllTo(lib_tests);
    } else if (@hasDecl(packages, "pkgs") and @hasDecl(packages.pkgs, "addAllTo")) { // gyro
        packages.pkgs.addAllTo(lib_tests);
    }

    const tests = b.step("test", "Run all library tests");
    const tests_run = b.addRunArtifact(lib_tests);
    tests.dependOn(&tests_run.step);
}

fn getBuildPrefix() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

fn getDependency(b: *Builder, comptime name: []const u8, comptime root: []const u8) !std.build.ModuleDependency {
    const path = comptime getBuildPrefix() ++ "/libs/" ++ name ++ "/" ++ root;

    // Make sure that the dependency has been checked out.
    std.fs.cwd().access(path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            std.log.err("zfetch: dependency '{s}' not checked out", .{name});

            return err;
        },
        else => return err,
    };

    return .{
        .name = name,
        .module = b.addModule(name, .{ .source_file = .{ .path = path } }),
    };
}

pub fn getPackage(b: *Builder) !std.build.ModuleDependency {
    var dependencies = b.allocator.alloc(std.build.ModuleDependency, 3) catch @panic("oom");

    dependencies[0] = try getDependency(b, "iguanaTLS", "src/main.zig");
    dependencies[1] = try getDependency(b, "uri", "uri.zig");
    dependencies[2] = try getDependency(b, "hzzp", "src/main.zig");

    return .{
        .name = "zfetch",
        .module = b.addModule("zfetch", .{
            .source_file = .{ .path = comptime getBuildPrefix() ++ "/src/main.zig" },
            .dependencies = dependencies,
        }),
    };
}
