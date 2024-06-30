use macroquad::prelude::*;

#[macroquad::main("Texture")]
async fn main() {
    let texture: Texture2D = load_texture("assets/ferris.png").await.unwrap();

    loop {
        clear_background(LIGHTGRAY);
        let w = screen_width();
        let proportion = screen_width() / texture.size()[0];
        let h = texture.size()[1] * proportion;
        draw_texture_ex(&texture, 0., (screen_height() - h) / 2., WHITE, DrawTextureParams { dest_size: Some(Vec2::new(w, h)),..Default::default() });
        next_frame().await
    }
}
