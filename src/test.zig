const std = @import("std");
const zfetch = @import("zfetch");

test "can http?" {
    try zfetch.init();
    defer zfetch.deinit();
    var conn = try zfetch.Connection.connect(std.testing.allocator, .{ .hostname = "en.wikipedia.org" });
    defer conn.close();

    try conn.writer().writeAll("GET / HTTP/1.1\r\nHost: en.wikipedia.org\r\nAccept: */*\r\n\r\n");

    const buf = try conn.reader().readUntilDelimiterAlloc(std.testing.allocator, '\r', std.math.maxInt(usize));
    defer std.testing.allocator.free(buf);

    try std.testing.expectEqualStrings("HTTP/1.1 301 Moved Permanently", buf);
}

test "can https?" {
    if (true) return error.SkipZigTest;
    try zfetch.init();
    defer zfetch.deinit();
    var conn = try zfetch.Connection.connect(std.testing.allocator, .{ .hostname = "en.wikipedia.org", .protocol = .https, .want_tls = true });
    defer conn.close();

    try conn.writer().writeAll("GET / HTTP/1.1\r\nHost: en.wikipedia.org\r\nAccept: */*\r\n\r\n");

    const buf = try conn.reader().readUntilDelimiterAlloc(std.testing.allocator, '\r', std.math.maxInt(usize));
    defer std.testing.allocator.free(buf);

    try std.testing.expectEqualStrings("HTTP/1.1 301 Moved Permanently", buf);
}

test "makes request" {
    try zfetch.init();
    defer zfetch.deinit();

    var req = try zfetch.Request.init(std.testing.allocator, "https://httpbin.org/get", null);
    defer req.deinit();

    try req.do(.GET, null, null);

    try std.testing.expect(@intFromEnum(req.status) == 200);
    try std.testing.expectEqualStrings("OK", req.status.phrase().?);
    try std.testing.expectEqualStrings("application/json", req.headers.get("content-type").?);

    const body = try req.reader().readAllAlloc(std.testing.allocator, 4 * 1024);
    defer std.testing.allocator.free(body);

    var tree = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, body, .{});
    defer tree.deinit();

    try std.testing.expectEqualStrings("https://httpbin.org/get", tree.value.object.get("url").?.string);
    try std.testing.expectEqualStrings("zfetch", tree.value.object.get("headers").?.object.get("User-Agent").?.string);
}

test "does basic auth" {
    try zfetch.init();
    defer zfetch.deinit();

    var req = try zfetch.Request.init(std.testing.allocator, "https://username:password@httpbin.org/basic-auth/username/password", null);
    defer req.deinit();

    try req.do(.GET, null, null);

    try std.testing.expect(@intFromEnum(req.status) == 200);
    try std.testing.expectEqualStrings("OK", req.status.phrase().?);
    try std.testing.expectEqualStrings("application/json", req.headers.get("content-type").?);

    const body = try req.reader().readAllAlloc(std.testing.allocator, 4 * 1024);
    defer std.testing.allocator.free(body);

    var tree = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, body, .{});
    defer tree.deinit();

    try std.testing.expect(tree.value.object.get("authenticated").?.bool == true);
    try std.testing.expectEqualStrings("username", tree.value.object.get("user").?.string);
}

test "can reset and resend" {
    try zfetch.init();
    defer zfetch.deinit();

    var headers = zfetch.Headers.init(std.testing.allocator);
    defer headers.deinit();

    try headers.appendValue("Connection", "keep-alive");

    var req = try zfetch.Request.init(std.testing.allocator, "https://httpbin.org/user-agent", null);
    defer req.deinit();

    try req.do(.GET, headers, null);

    try std.testing.expect(@intFromEnum(req.status) == 200);
    try std.testing.expectEqualStrings("OK", req.status.phrase().?);
    try std.testing.expectEqualStrings("application/json", req.headers.get("content-type").?);

    const body = try req.reader().readAllAlloc(std.testing.allocator, 4 * 1024);
    defer std.testing.allocator.free(body);

    var tree = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, body, .{});
    defer tree.deinit();

    try std.testing.expectEqualStrings("zfetch", tree.value.object.get("user-agent").?.string);

    try req.reset("https://httpbin.org/get");

    try req.do(.GET, null, null);

    try std.testing.expect(@intFromEnum(req.status) == 200);
    try std.testing.expectEqualStrings("OK", req.status.phrase().?);
    try std.testing.expectEqualStrings("application/json", req.headers.get("content-type").?);

    const body1 = try req.reader().readAllAlloc(std.testing.allocator, 4 * 1024);
    defer std.testing.allocator.free(body1);

    var tree1 = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, body1, .{});
    defer tree1.deinit();

    try std.testing.expectEqualStrings("https://httpbin.org/get", tree1.value.object.get("url").?.string);
    try std.testing.expectEqualStrings("zfetch", tree1.value.object.get("headers").?.object.get("User-Agent").?.string);
}
