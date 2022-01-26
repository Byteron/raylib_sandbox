use std::{collections::HashMap, time::Instant};

use bevy_ecs::prelude::*;
use rand::Rng;
use raylib::prelude::*;

#[derive(Component, Debug)]
struct Position {
    x: f32,
    y: f32,
}

#[derive(Component, Debug)]
struct Velocity {
    dx: f32,
    dy: f32,
}

#[derive(Component, Debug)]
struct Renderable {
    texture_id: &'static str,
}

#[derive(Default)]
struct Textures {
    vec: HashMap<&'static str, Texture2D>,
}

impl Textures {
    fn insert(&mut self, name: &'static str, texture: Texture2D) -> usize {
        self.vec.insert(name, texture);
        self.vec.len() - 1
    }

    fn get(&self, name: &'static str) -> Option<&Texture2D> {
        self.vec.get(name)
    }
}

fn main() {
    let (mut handle, thread) = raylib::init()
        .size(1280, 720)
        .title("Hello, World")
        .resizable()
        .build();

    handle.set_target_fps(60);

    let mut world = World::default();

    world.insert_resource(Textures::default());
    world.insert_non_send(thread);
    world.insert_resource(handle);

    let mut startup_stage = SystemStage::parallel();
    let mut update_stage = SystemStage::parallel();
    let mut render_stage = SystemStage::parallel();

    startup_stage.add_system(setup.system());
    update_stage.add_system(movement.system());
    render_stage.add_system(render.system());

    startup_stage.run(&mut world);

    loop {
        render_stage.run(&mut world);
        update_stage.run(&mut world);

        let handle = world.get_resource::<RaylibHandle>().unwrap();

        if handle.window_should_close() {
            break;
        }
    }
}

fn setup(
    mut commands: Commands,
    mut handle: ResMut<RaylibHandle>,
    mut textures: ResMut<Textures>,
    thread: NonSend<RaylibThread>,
) {
    let texture = handle
        .load_texture(&thread, "assets/images/goblin.png")
        .unwrap();

    textures.insert("goblin", texture);

    let mut rng = rand::thread_rng();

    for x in 0..20 {
        for y in 0..20 {
            commands
                .spawn()
                .insert(Position {
                    x: x as f32,
                    y: y as f32,
                })
                .insert(Velocity {
                    dx: rng.gen_range(-2.0..2.0),
                    dy: rng.gen_range(-2.0..2.0),
                })
                .insert(Renderable {
                    texture_id: "goblin",
                });
        }
    }
}

fn movement(mut query: Query<(&mut Position, &mut Velocity)>) {
    for (mut pos, mut vel) in query.iter_mut() {
        pos.x += vel.dx;
        pos.y += vel.dy;

        if pos.x < 0.0 || pos.x > 1280.0 {
            vel.dx = -vel.dx;
        }

        if pos.y < 0.0 || pos.y > 720.0 {
            vel.dy = -vel.dy;
        }
    }
}

fn render(
    mut handle: ResMut<RaylibHandle>,
    thread: NonSend<RaylibThread>,
    textures: Res<Textures>,
    query: Query<(&Position, &Renderable)>,
) {
    let now = Instant::now();

    let mut draw = handle.begin_drawing(&thread);
    draw.clear_background(Color::BLACK);

    for (position, renderable) in query.iter() {
        draw.draw_texture(
            textures.get(renderable.texture_id).unwrap(),
            position.x as i32,
            position.y as i32,
            Color::WHITE,
        );
    }

    draw.draw_text(
        format!("Entities Rendered: {}", query.iter().len()).as_str(),
        0,
        0,
        16,
        Color::WHITE,
    );
    draw.draw_text(
        format!("Render System Time: {:?}", now.elapsed()).as_str(),
        0,
        20,
        16,
        Color::WHITE,
    );
    draw.draw_fps(10, 40);
}
