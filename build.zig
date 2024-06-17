const std = @import("std");

pub fn build(b: *std.Build) !void {
    const bundle = b.option(bool, "bundle", "Bundle SQLite") orelse false;

    const sqlite = b.addModule("fridge", .{
        .root_source_file = b.path("src/main.zig"),
    });
    sqlite.link_libc = true;

    if (bundle) {
        const src = b.dependency("sqlite_source", .{});
        sqlite.addIncludePath(src.path("."));
        sqlite.addCSourceFile(.{ .file = src.path("sqlite3.c"), .flags = &.{"-std=c99"} });
    } else {
        // sqlite.linkSystemLibrary("sqlite3", .{});
        try sqlite.link_objects.append(b.allocator, .{
            .system_lib = .{
                .name = b.dupe("sqlite3"),
                .needed = false,
                .weak = false,
                .use_pkg_config = .yes,
                .preferred_link_mode = .dynamic,
                .search_strategy = .paths_first,
            },
        });
    }

    const tests = b.addTest(.{ .root_source_file = b.path("src/main.zig") });
    tests.root_module.link_objects = sqlite.link_objects;
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
