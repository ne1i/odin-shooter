package app
import fmt "core:fmt"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

Screens :: enum {
	START_MENU,
	START_MENU_ONLINE,
	GAME,
	GAME_OVER,
}

Controls :: enum {
	ZQSD,
	OKLM,
}

LaserValues :: enum {
	WIDTH  = 30,
	HEIGHT = 4,
	SPEED  = 12,
}

Laser :: struct {
	rec:     rl.Rectangle,
	shot_by: PlayerId,
}

PlayerId :: enum {
	PLAYER1,
	PLAYER2,
}

GameStatuses :: enum {
	PLAYER1_WON,
	PLAYER2_WON,
	RUNNING,
}

SCREEN_WIDTH: i32 = 800
SCREEN_HEIGHT: i32 = 600
TARGET_FPS: i32 = 120
BASE_PLAYER_SPEED: f32 = 3
PLAYER_ATTACK_SPEED: f32 = 0.01

player1_attack_timer: f32 = 1
player2_attack_timer: f32 = 1

ATTACK_SPEED_BONUS_DROP_RATE: f32 = 0.1 / cast(f32)TARGET_FPS // 1/10 chance every second

BONUS_WIDTH: f32 = 20
BONUS_HEIGHT: f32 = 20

MIDDLE_BAR_WIDTH: f32 = 6
MIDDLE_BAR_HEIGHT: f32 = cast(f32)SCREEN_HEIGHT
MIDDLE_BAR_X: f32 = cast(f32)(SCREEN_WIDTH / 2) - MIDDLE_BAR_WIDTH / 2

PLAYER_WIDTH: f32 = 15
PLAYER_HEIGHT: f32 = 15
PLAYER_START_X_OFFSET: f32 = 0.25
PLAYER_START_Y_OFFSET: f32 = 0.5

CHARGE_BAR_WIDTH: f32 = 80
CHARGE_BAR_HEIGHT: f32 = 15
CHARGE_BAR_X_OFFSET: f32 = 10
CHARGE_BAR_Y_OFFSET: f32 = 25
CHARGE_BAR_BORDER: f32 = 3

GAME_STATUS: GameStatuses = GameStatuses.RUNNING

current_screen: Screens = Screens.START_MENU

middle_bar: rl.Rectangle
bonus_rec: rl.Rectangle
bonus_active: bool
lasers: [dynamic]Laser

EPS: f32 = 0.0001

main :: proc() {
	player1: rl.Rectangle
	player1.width = PLAYER_WIDTH
	player1.height = PLAYER_HEIGHT
	player1.x = cast(f32)SCREEN_WIDTH * PLAYER_START_X_OFFSET - player1.width
	player1.y = cast(f32)SCREEN_HEIGHT * PLAYER_START_Y_OFFSET - player1.height

	player2: rl.Rectangle
	player2.width = PLAYER_WIDTH
	player2.height = PLAYER_HEIGHT
	player2.x = cast(f32)(SCREEN_WIDTH -
		cast(i32)(cast(f32)SCREEN_WIDTH * PLAYER_START_X_OFFSET) -
		cast(i32)player2.width)
	player2.y = cast(f32)SCREEN_HEIGHT * PLAYER_START_Y_OFFSET - player2.height


	middle_bar.width = MIDDLE_BAR_WIDTH
	middle_bar.height = MIDDLE_BAR_HEIGHT
	middle_bar.x = MIDDLE_BAR_X
	middle_bar.y = 0


	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "2sg")
	monitor := rl.GetCurrentMonitor()
	rl.SetTargetFPS(TARGET_FPS)
	for (!rl.WindowShouldClose()) {
		switch (current_screen) {
		case Screens.START_MENU:
			main_menu()
			break
		case Screens.START_MENU_ONLINE:
			main_menu_online()
		case Screens.GAME:
			game(&player1, &player2)
			break
		case Screens.GAME_OVER:
			game_over()
			break
		}

	}
	rl.CloseWindow()
}

main_menu :: proc() {

	rl.BeginDrawing()

	start_menu_text: cstring = "Press ENTER for local"
	start_menu_text_font_size: i32 = 50
	start_menu_text_width := rl.MeasureText(start_menu_text, start_menu_text_font_size)
	rl.DrawText(
		start_menu_text,
		(SCREEN_WIDTH / 2) - start_menu_text_width / 2,
		SCREEN_HEIGHT / 3,
		start_menu_text_font_size,
		rl.WHITE,
	)

	online_mode_text: cstring = "Press RSHIFT for online"
	online_mode_text_font_size: i32 = 50
	online_mode_text_width := rl.MeasureText(online_mode_text, online_mode_text_font_size)
	rl.DrawText(
		online_mode_text,
		(SCREEN_WIDTH / 2) - online_mode_text_width / 2,
		SCREEN_HEIGHT / 2,
		online_mode_text_font_size,
		rl.WHITE,
	)
	rl.ClearBackground(rl.BLACK)
	rl.EndDrawing()
	if (rl.IsKeyPressed(rl.KeyboardKey.ENTER)) {
		current_screen = Screens.GAME
	}

	if (rl.IsKeyPressed(rl.KeyboardKey.RIGHT_SHIFT)) {
		current_screen = Screens.START_MENU_ONLINE
	}

}

main_menu_online :: proc() {
	rl.BeginDrawing()
	enter_ip_text: cstring = "Please enter\n player 2 IP address"
	enter_ip_text_font_size: i32 = 50
	enter_ip_text_width := rl.MeasureText(enter_ip_text, enter_ip_text_font_size)
	rl.DrawText(
		enter_ip_text,
		(SCREEN_WIDTH / 2) - enter_ip_text_width / 2,
		SCREEN_HEIGHT / 3,
		enter_ip_text_font_size,
		rl.WHITE,
	)
	rl.DrawRectangleLines(150, 400, 500, 100, rl.WHITE)
	rl.ClearBackground(rl.BLACK)
	rl.EndDrawing()
}

game :: proc(pplayer1: ^rl.Rectangle, pplayer2: ^rl.Rectangle) {
	rl.BeginDrawing()

	handle_player_movement(pplayer1, Controls.ZQSD)
	handle_player_movement(pplayer2, Controls.OKLM)
	handle_player_attack_move(pplayer1^, Controls.ZQSD)
	handle_player_attack_move(pplayer2^, Controls.OKLM)

	if (player1_attack_timer < 1) {
		player1_attack_timer += PLAYER_ATTACK_SPEED
	}

	if (player2_attack_timer < 1) {
		player2_attack_timer += PLAYER_ATTACK_SPEED
	}

	if (GAME_STATUS != GameStatuses.RUNNING) {
		reset_game(pplayer1, pplayer2)
		current_screen = Screens.GAME_OVER
	}
	handle_lasers(pplayer1^, pplayer2^)
	// handle_bonuses()
	draw_charge_bars()
	rl.DrawRectangleRec(middle_bar, rl.WHITE)
	rl.DrawRectangleRec(pplayer1^, rl.RED)
	rl.DrawRectangleRec(pplayer2^, rl.RED)

	rl.ClearBackground(rl.BLACK)
	rl.EndDrawing()
}


handle_player_movement :: proc(pplayer: ^rl.Rectangle, controls: Controls) {

	if (controls == Controls.ZQSD) {
		if (rl.IsKeyDown(rl.KeyboardKey.W) && player_can_go_up(pplayer^)) {
			pplayer^.y -= BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.A) && player1_can_go_left(pplayer^)) {
			pplayer^.x -= BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.S) && player_can_go_down(pplayer^)) {
			pplayer^.y += BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.D) && player1_can_go_right(pplayer^)) {
			pplayer^.x += BASE_PLAYER_SPEED
		}
	}

	if (controls == Controls.OKLM) {
		if (rl.IsKeyDown(rl.KeyboardKey.O) && player_can_go_up(pplayer^)) {
			pplayer^.y -= BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.K) && player2_can_go_left(pplayer^)) {
			pplayer^.x -= BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.L) && player_can_go_down(pplayer^)) {
			pplayer^.y += BASE_PLAYER_SPEED
		}
		if (rl.IsKeyDown(rl.KeyboardKey.SEMICOLON) && player2_can_go_right(pplayer^)) {
			pplayer^.x += BASE_PLAYER_SPEED
		}
	}
}

player_can_go_up :: proc(player: rl.Rectangle) -> bool {
	if (player.y <= 0) {
		return false
	}
	return true
}

player_can_go_down :: proc(player: rl.Rectangle) -> bool {
	if (player.y + player.height >= cast(f32)SCREEN_HEIGHT) {
		return false
	}
	return true
}

player1_can_go_left :: proc(player: rl.Rectangle) -> bool {
	if (player.x <= 0) {
		return false
	}
	return true
}

player2_can_go_right :: proc(player: rl.Rectangle) -> bool {
	if (player.x + player.width >= cast(f32)SCREEN_WIDTH) {
		return false
	}
	return true
}

player2_can_go_left :: proc(player: rl.Rectangle) -> bool {
	if (player.x <= MIDDLE_BAR_X + MIDDLE_BAR_WIDTH) {
		return false
	}
	return true
}

player1_can_go_right :: proc(player: rl.Rectangle) -> bool {
	if (player.x + player.width >= cast(f32)(MIDDLE_BAR_X)) {
		return false
	}
	return true
}


handle_player_attack_move :: proc(player: rl.Rectangle, controls: Controls) {
	if (controls == Controls.ZQSD) {
		if (rl.IsKeyDown(rl.KeyboardKey.SPACE) && player1_attack_timer >= 1 - EPS) {
			laser: Laser
			laser.rec.height = cast(f32)LaserValues.HEIGHT
			laser.rec.width = cast(f32)LaserValues.WIDTH
			laser.rec.x = player.x
			laser.rec.y = player.y + player.height / 2 - laser.rec.height / 2

			laser.shot_by = PlayerId.PLAYER1
			append(&lasers, laser)
			player1_attack_timer = 0
		}
	}

	if (controls == Controls.OKLM) {
		if (rl.IsKeyDown(rl.KeyboardKey.RIGHT_SHIFT) && player2_attack_timer >= 1 - EPS) {
			laser: Laser
			laser.rec.height = cast(f32)LaserValues.HEIGHT
			laser.rec.width = cast(f32)LaserValues.WIDTH
			laser.rec.x = player.x
			laser.rec.y = player.y + player.height / 2 - laser.rec.height / 2

			laser.shot_by = PlayerId.PLAYER2
			append(&lasers, laser)
			player2_attack_timer = 0

		}
	}
}

handle_lasers :: proc(player1: rl.Rectangle, player2: rl.Rectangle) {
	for &laser, index in lasers {
		if (laser.shot_by == PlayerId.PLAYER1) {
			laser.rec.x += cast(f32)LaserValues.SPEED
			rl.DrawRectangleRec(laser.rec, rl.BLUE)

			if (rl.CheckCollisionRecs(player2, laser.rec)) {
				GAME_STATUS = GameStatuses.PLAYER1_WON
				return
			}


		}

		if (laser.shot_by == PlayerId.PLAYER2) {
			laser.rec.x -= cast(f32)LaserValues.SPEED
			rl.DrawRectangleRec(laser.rec, rl.GREEN)
			if (rl.CheckCollisionRecs(player1, laser.rec)) {
				GAME_STATUS = GameStatuses.PLAYER2_WON
				return
			}

		}

		if (is_laser_out_of_bounds(laser)) {
			unordered_remove(&lasers, index)
		}
	}
}

is_laser_out_of_bounds :: proc(laser: Laser) -> bool {
	if (laser.rec.x < 0 || laser.rec.x > cast(f32)SCREEN_WIDTH) {
		return true
	}
	if (laser.rec.y < 0 || laser.rec.y > cast(f32)SCREEN_HEIGHT) {
		return true
	}
	return false
}


game_over :: proc() {
	rl.BeginDrawing()

	player_won_text := GAME_STATUS == GameStatuses.PLAYER1_WON ? "Player 1 won" : "Player 2 won"
	start_menu_text_string := strings.concatenate([]string{"Game Over ! ", player_won_text})
	start_menu_text: cstring = strings.clone_to_cstring(start_menu_text_string)
	start_menu_text_font_size: i32 = 50
	start_menu_text_width := rl.MeasureText(start_menu_text, start_menu_text_font_size)
	rl.DrawText(
		start_menu_text,
		(SCREEN_WIDTH / 2) - start_menu_text_width / 2,
		SCREEN_HEIGHT / 3,
		start_menu_text_font_size,
		rl.RED,
	)

	// rl.ClearBackground(rl.BLACK)
	rl.EndDrawing()
	if (rl.IsKeyPressed(rl.KeyboardKey.ENTER)) {
		GAME_STATUS = GameStatuses.RUNNING
		current_screen = Screens.START_MENU

	}
}

reset_game :: proc(player1: ^rl.Rectangle, player2: ^rl.Rectangle) {
	clear(&lasers)
	player1_attack_timer = 1
	player2_attack_timer = 1
	player1.x = cast(f32)SCREEN_WIDTH * PLAYER_START_X_OFFSET - player1.width
	player1.y = cast(f32)SCREEN_HEIGHT * PLAYER_START_Y_OFFSET - player1.height
	player2.x = cast(f32)(SCREEN_WIDTH -
		cast(i32)(cast(f32)SCREEN_WIDTH * PLAYER_START_X_OFFSET) -
		cast(i32)player2.width)
	player2.y = cast(f32)SCREEN_HEIGHT * PLAYER_START_Y_OFFSET - player2.height
	bonus_active = false
}

draw_charge_bars :: proc() {
	charge_bar1_bg := rl.Rectangle {
		CHARGE_BAR_X_OFFSET,
		cast(f32)SCREEN_HEIGHT - CHARGE_BAR_Y_OFFSET,
		CHARGE_BAR_WIDTH,
		CHARGE_BAR_HEIGHT,
	}
	charge_bar2_bg := rl.Rectangle {
		cast(f32)SCREEN_WIDTH - CHARGE_BAR_WIDTH - CHARGE_BAR_X_OFFSET,
		cast(f32)SCREEN_HEIGHT - CHARGE_BAR_Y_OFFSET,
		CHARGE_BAR_WIDTH,
		CHARGE_BAR_HEIGHT,
	}
	rl.DrawRectangleRec(charge_bar1_bg, rl.DARKGRAY)
	rl.DrawRectangleRec(charge_bar2_bg, rl.DARKGRAY)

	charge_bar1 := rl.Rectangle {
		CHARGE_BAR_X_OFFSET,
		cast(f32)SCREEN_HEIGHT - CHARGE_BAR_Y_OFFSET,
		CHARGE_BAR_WIDTH * player1_attack_timer,
		CHARGE_BAR_HEIGHT,
	}
	charge_bar2 := rl.Rectangle {
		cast(f32)SCREEN_WIDTH - CHARGE_BAR_WIDTH - CHARGE_BAR_X_OFFSET,
		cast(f32)SCREEN_HEIGHT - CHARGE_BAR_Y_OFFSET,
		CHARGE_BAR_WIDTH * player2_attack_timer,
		CHARGE_BAR_HEIGHT,
	}
	rl.DrawRectangleRec(charge_bar1, rl.GREEN)
	rl.DrawRectangleRec(charge_bar2, rl.GREEN)
	rl.DrawRectangleLinesEx(charge_bar1_bg, CHARGE_BAR_BORDER, rl.WHITE)
	rl.DrawRectangleLinesEx(charge_bar2_bg, CHARGE_BAR_BORDER, rl.WHITE)

}

handle_bonuses :: proc() {
	if (!bonus_active) {
		attack_speed_drop := rand.float32()
		if (attack_speed_drop < ATTACK_SPEED_BONUS_DROP_RATE) {
			bonus_rec.width = BONUS_WIDTH
			bonus_rec.height = BONUS_HEIGHT
			bonus_rec.y = rand.float32() * (cast(f32)SCREEN_HEIGHT - BONUS_HEIGHT)

			max_x_left := MIDDLE_BAR_X - BONUS_WIDTH
			max_x_right := cast(f32)SCREEN_WIDTH - BONUS_WIDTH

			if (rand.float32() < 0.5) {
				bonus_rec.x = rand.float32() * max_x_left
			} else {
				bonus_rec.x =
					MIDDLE_BAR_X +
					MIDDLE_BAR_WIDTH +
					rand.float32() * (max_x_right - (MIDDLE_BAR_X + MIDDLE_BAR_WIDTH))
			}

			bonus_active = true
		}
	} else {
		rl.DrawRectangleRec(bonus_rec, rl.RED)
	}
}
