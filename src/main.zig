const std = @import("std");
const zecs = @import("zecs");
const World = zecs.World;
const System = zecs.System;

const rl = @cImport({
    @cInclude("raylib.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    var world = try World.init(allocator);
    defer world.deinit();

    try benchSetup(&world);
    try benchSystem(&world);
    try bench(&world, benchSystem);
    try bench(&world, fastBenchSystem);
    // rl.InitWindow(800, 600, "raylib [core] example - basic window");
    // defer rl.CloseWindow();

    // rl.SetTargetFPS(60);

    // var texture = rl.LoadTexture("icon.png");
    // try setup(&world, texture);

    // while (!rl.WindowShouldClose()) {
    //     try moveSystem(&world);
    //     try renderSystem(&world);
    // }

    // rl.UnloadTexture(texture);
}

const test_runs: u32 = 10;
const Timer = std.time.Timer;
fn bench(world: *World, system: System) !void {
    var counter: u32 = test_runs;
    var timer = try Timer.start();
    var time: u64 = 0;

    while (counter > 0) {
        try system(world);
        time += timer.lap();
        counter -= 1;
    }

    std.debug.print("ns: {}\n", .{time / test_runs});
}

const C1 = struct {
    value: u32 = 0,
};

const C2 = struct {
    value: u32 = 0,
};

const P1 = struct {
    value: u32 = 0,
};

const P2 = struct {
    value: u32 = 0,
};

const P3 = struct {
    value: u32 = 0,
};

const P4 = struct {
    value: u32 = 0,
};

fn benchSetup(world: *World) !void {
    var index: u32 = 0;
    while (index < 100000) : (index += 1) {
        const e = try world.entities.spawn();
        try world.entities.set(C1, e, .{});
        try world.entities.set(C2, e, .{ .value = 1 });

        switch (index % @as(u32, 4)) {
            0 => try world.entities.set(P1, e, .{}),
            1 => try world.entities.set(P2, e, .{}),
            2 => try world.entities.set(P3, e, .{}),
            3 => try world.entities.set(P4, e, .{}),
            else => unreachable,
        }
    }
}

fn benchSystem(world: *World) !void {
    var query = try world.query(.{ .c1 = C1, .c2 = C2 });
    var it = query.iter();
    while (it.next()) |e| {
        e.c1.value += e.c2.value;
    }
}

fn fastBenchSystem(world: *World) !void {
    var query = try world.query(.{ .c1 = C1, .c2 = C2 });
    for (query.tables.items) |t| {
        var index: u32 = 0;
        var c1 = t.getStorage(C1).?;
        var c2 = t.getStorage(C2).?;
        while (index < t.len) : (index += 1) {
            c1[index].value += c2[index].value;
        }
    }
}
const Position = struct {
    x: f32,
    y: f32,
};

const Velocity = struct {
    x: f32,
    y: f32,
};

const Sprite = struct {
    texture: rl.Texture2D,
};

fn setup(world: *World, texture: rl.Texture2D) !void {
    var rnd = std.rand.DefaultPrng.init(0);

    var y: u32 = 0;
    while (y < 10) : (y += 1) {
        var x: u32 = 0;
        while (x < 10) : (x += 1) {
            var e = try world.entities.spawn();
            var rx = rnd.random().int(i32);
            var ry = rnd.random().int(i32);

            var dx = @rem(rx, 10) - @as(i32, 5);
            var dy = @rem(ry, 10) - @as(i32, 5);

            try world.entities.set(Position, e, .{ .x = @intToFloat(f32, x * 64), .y = @intToFloat(f32, y * 64) });
            try world.entities.set(Velocity, e, .{ .x = @intToFloat(f32, dx), .y = @intToFloat(f32, dy) });
            try world.entities.set(Sprite, e, .{ .texture = texture });
        }
    }
}

fn moveSystem(world: *World) !void {
    var query = try world.query(.{ .pos = Position, .vel = Velocity });
    var it = query.iter();

    const width = @intToFloat(f32, rl.GetRenderWidth());
    const height = @intToFloat(f32, rl.GetRenderHeight());

    while (it.next()) |e| {
        e.pos.x += e.vel.x;
        e.pos.y += e.vel.y;

        if (e.pos.x < 0 or e.pos.x > width) {
            e.vel.x = -e.vel.x;
        }

        if (e.pos.y < 0 or e.pos.y > height) {
            e.vel.y = -e.vel.y;
        }

        e.pos.x = std.math.clamp(e.pos.x, 0, width);
        e.pos.y = std.math.clamp(e.pos.y, 0, height);
    }
}

fn renderSystem(world: *World) !void {
    var query = try world.query(.{ .sprite = Sprite, .pos = Position });

    rl.BeginDrawing();
    rl.ClearBackground(rl.WHITE);

    var it = query.iter();
    while (it.next()) |e| {
        rl.DrawTexture(e.sprite.texture, @floatToInt(i32, e.pos.x), @floatToInt(i32, e.pos.y), rl.WHITE);
    }

    rl.EndDrawing();
}
