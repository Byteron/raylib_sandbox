const std = @import("std");
const zecs = @import("zecs");
const App = @import("app.zig").App;
const Stage = @import("app.zig").Stage;
const World = zecs.World;
const System = zecs.System;

const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var app = try App.init(allocator);
    defer app.deinit();

    _ = app
        .addPlugin(renderPlugin)
        .addPlugin(gamePlugin);

    try app.run();

    // var world = try World.init(allocator);
    // defer world.deinit();

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

fn renderPlugin(app: *App) !void {
    _ = app.addSystem(.render, renderSystem);
}

fn gamePlugin(app: *App) !void {
    _ = app
        .addSystem(.startup, spawnSystem)
        .addSystem(.update, moveSystem);
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

fn spawnSystem(world: *World) !void {
    var rnd = std.rand.DefaultPrng.init(0);
    var texture = rl.LoadTexture("icon.png");

    var y: u32 = 0;
    while (y < 10) : (y += 1) {
        var x: u32 = 0;
        while (x < 10) : (x += 1) {
            var rx = rnd.random().int(i32);
            var ry = rnd.random().int(i32);

            var dx = @rem(rx, 10) - @as(i32, 5);
            var dy = @rem(ry, 10) - @as(i32, 5);

            _ = world.spawn()
                .set(Position, .{ .x = @intToFloat(f32, x * 64), .y = @intToFloat(f32, y * 64) })
                .set(Velocity, .{ .x = @intToFloat(f32, dx), .y = @intToFloat(f32, dy) })
                .set(Sprite, .{ .texture = texture });
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
