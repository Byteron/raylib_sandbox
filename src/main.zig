const std = @import("std");
const zecs = @import("zecs");
const World = zecs.World;

const rl = @cImport({
    @cInclude("raylib.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    var world = try World.init(allocator);
    defer world.deinit();

    rl.InitWindow(800, 600, "raylib [core] example - basic window");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var texture = rl.LoadTexture("icon.png");
    try setup(&world, texture);

    while (!rl.WindowShouldClose()) {
        try renderSystem(&world);
    }

    rl.UnloadTexture(texture);
}

const Position = struct {
    x: f32,
    y: f32,
};

const Sprite = struct {
    texture: rl.Texture2D,
};

fn setup(world: *World, texture: rl.Texture2D) !void {
    var y: u32 = 0;
    while (y < 10) : (y += 1) {
        var x: u32 = 0;
        while (x < 10) : (x += 1) {
            var e = try world.entities.spawn();
            try world.entities.set(Position, e, .{ .x = @intToFloat(f32, x * 64), .y = @intToFloat(f32, y * 64) });
            try world.entities.set(Sprite, e, .{ .texture = texture });
        }
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
