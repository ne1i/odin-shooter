package app
import "core:fmt"
import rl "vendor:raylib"

Screens :: enum {
	START_MENU,
	GAME,
}

Controls :: enum {
	ZQSD,
	OKLM,
}

SCREEN_WIDTH: i32 = 800
SCREEN_HEIGHT: i32 = 600

BASE_PLAYER_SPEED: f32 = 3

MIDDLE_BAR_WIDTH: f32 = 6
MIDDLE_BAR_HEIGHT: f32 = cast(f32)SCREEN_HEIGHT
MIDDLE_BAR_X: f32 = cast(f32)(SCREEN_WIDTH / 2) - MIDDLE_BAR_WIDTH / 2

current_screen: Screens = Screens.START_MENU

main :: proc() {
	player1: rl.Rectangle
	player1.width = 15
	player1.height = 15
	player1.x = cast(f32)SCREEN_WIDTH / 4 - player1.width
	player1.y = cast(f32)SCREEN_HEIGHT / 2 - player1.height

	player2: rl.Rectangle
	player2.width = 15
	player2.height = 15
	player2.x = cast(f32)(SCREEN_WIDTH - (SCREEN_WIDTH / 4) - cast(i32)player2.width)
	player2.y = cast(f32)SCREEN_HEIGHT / 2 - player2.height

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "2sg")
	monitor := rl.GetCurrentMonitor()
	rl.SetTargetFPS(120)
	for (!rl.WindowShouldClose()) {
		switch (current_screen) {
		case Screens.START_MENU:
			main_menu()
			break
		case Screens.GAME:
			game(&player1, &player2)
			break
		}

	}
	rl.CloseWindow()
}

main_menu :: proc() {

	rl.BeginDrawing()

	start_menu_text: cstring = "Press ENTER"
	start_menu_text_font_size: i32 = 50
	start_menu_text_width := rl.MeasureText(start_menu_text, start_menu_text_font_size)
	rl.DrawText(
		start_menu_text,
		(SCREEN_WIDTH / 2) - start_menu_text_width / 2,
		SCREEN_HEIGHT / 3,
		start_menu_text_font_size,
		rl.WHITE,
	)

	rl.ClearBackground(rl.BLACK)
	rl.EndDrawing()
	if (rl.IsKeyPressed(rl.KeyboardKey.ENTER)) {
		current_screen = Screens.GAME
	}

}

game :: proc(pplayer1: ^rl.Rectangle, pplayer2: ^rl.Rectangle) {
	rl.BeginDrawing()

	middle_bar: rl.Rectangle
	middle_bar.width = MIDDLE_BAR_WIDTH
	middle_bar.height = MIDDLE_BAR_HEIGHT
	middle_bar.x = MIDDLE_BAR_X
	middle_bar.y = 0

	handle_player_movement(pplayer1, Controls.ZQSD)
	handle_player_movement(pplayer2, Controls.OKLM)


	rl.DrawRectangleRec(middle_bar, rl.WHITE)
	rl.DrawRectangleRec(pplayer1^, rl.RED)
	rl.DrawRectangleRec(pplayer2^, rl.RED)


	rl.ClearBackground(rl.BLACK)
	rl.EndDrawing()
}


handle_player_movement :: proc(pplayer: ^rl.Rectangle, controls: Controls) {

	if (controls == Controls.ZQSD) {
		if (rl.IsKeyDown(rl.KeyboardKey.W)) {
			pplayer^.y -= BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.A)) {
			pplayer^.x -= BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.S)) {
			pplayer^.y += BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.D)) {
			pplayer^.x += BASE_PLAYER_SPEED
		}
	}

	if (controls == Controls.OKLM) {
		if (rl.IsKeyDown(rl.KeyboardKey.O)) {
			pplayer^.y -= BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.K)) {
			pplayer^.x -= BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.L)) {
			pplayer^.y += BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.SEMICOLON)) {
			pplayer^.x += BASE_PLAYER_SPEED
		}
	}
}
