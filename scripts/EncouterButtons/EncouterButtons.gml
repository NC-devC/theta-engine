function EncouterButtonFight() : EncouterButton() constructor {
	self.sprite = engine_encouter_default_button_fight_sprite;
	self.soul_offset = -36;
	
	self.selection = 0;
	self.enemy_selected = undefined;
	
	/// @param {Id.Instance} hud
	static update_input = function(hud) {
		var encouter = hud.encouter;
		var enemies = encouter.enemies_instance;
		
		if (input_pressed(input_source.skip)) {
			close(hud);
		}
		
		if (input_pressed(input_source.select)) {
			close(hud);
			encouter.set_state(encouter_state.atacking);
			instance_create(obj_encouter_attack, {
				encouter: encouter,
				target: selection,
			});
			
			audio_play_sound(snd_ui_select, 0, false);
		}
		
		if (enemy_selected != undefined) return;
		
		if (input_pressed(input_source.up) && selection > 0) {
			audio_play_sound(snd_ui_selecting, 0, false);
			selection--;
		}
	
		if (input_pressed(input_source.down) && selection < array_length(enemies) - 1) {
			audio_play_sound(snd_ui_selecting, 0, false);
			selection++;
		}
	}
	
	/// @param {Id.Instance} hud
	static draw_menu = function(hud) {
		update_input(hud);
		
		var encouter = hud.encouter;
		var arena = hud.arena;
		var enemies = encouter.enemies_instance;
		
		if (enemy_selected != undefined) return;
		
		var text_offset_x = hud.text_offset_x;
		var text_offset_y = hud.text_offset_y;
		var text = "";

		for (var i = 0; i < array_length(enemies); i ++) {
			var enemy = enemies[i];
			var bar_offset_x = 16;
			var bar_offset_y = 34;
			var bar_draw_x = arena.x - arena.width / 2 + bar_offset_x;
			var bar_draw_y = arena.y - arena.height / 2 + bar_offset_y + 32 * i;
			var soul_offset_x = 12;
			var soul_offset_y = -8;
			var name = enemy.name;
		
			// Draw enemy hp bar
			draw_sprite(spr_ui_encouter_menu_bar_background, 0, bar_draw_x + 350, bar_draw_y - 14);
			draw_sprite_field(spr_ui_encouter_menu_bar_hp, 0, bar_draw_x + 350, bar_draw_y - 14, enemy.hp / enemy.hp_max);
		
			// Draw soul & generate text
			if (selection == i) {
				draw_sprite(spr_ui_encouter_button_soul, 0, bar_draw_x + soul_offset_x, bar_draw_y + soul_offset_y);
				text += "    ";
			} else {
				text += "* ";
			}
				
			text += name + "\n";
		}

		// Draw enemy names
		scribble(text)
			.transform(2, 2, 0)
			.line_height(16, 16)
			.draw(arena.x - arena.width / 2 + text_offset_x, arena.y - arena.height / 2 + text_offset_y);
	}
}

function EncouterButtonAct() : EncouterButton() constructor {
	self.sprite = engine_encouter_default_button_act_sprite;
	self.soul_offset = -30;
	self.soul_sprite = spr_ui_encouter_button_soul;
		
	self.selection = 0;
	
	// Hashable values,
	// so as not to fuck up the encounter with calls in drawing
	self.enemy = undefined;
	self.action = undefined;
	self.actions = undefined;
	
	// Aren't the best option,
	// but it's not worthy of its own enum
	self.states = {
		select_enemy: 0,
		select_action: 1,
	}
	
	// State machine, lmao
	self.state = states.select_enemy;

	// Settings for rendering
	self.bar_offset_x = 16;
	self.bar_offset_y = 34;
	self.soul_offset_x = 12;
	self.soul_offset_y = -8;
	
	/// @param {Id.Instance} hud
	static update_input = function(hud) {
		var encouter = hud.encouter;
		var enemies = encouter.enemies_instance;
		
		if (input_pressed(input_source.skip)) {
			switch (state) {
				case states.select_enemy:
					enemy = undefined;
					actions = undefined;

					close(hud);
					break;
					
				case states.select_action:
					action = undefined;

					state = states.select_enemy;
					break;
			}
			
			selection = 0;
		}
		
		if (input_pressed(input_source.select)) {
			switch (state) {
				case states.select_enemy:
					enemy = encouter.enemies_instance[selection];
					actions = enemy.actions;
					
					selection = 0;
					state = states.select_action;
					break;
					
				case states.select_action:
					action = actions[selection];
					action.invoke(encouter);
					break;
			}
			
			audio_play_sound(snd_ui_select, 0, false);
			selection = 0;
		}
		
		// Slection
		var input_direction_y = input_pressed(input_source.down) - input_pressed(input_source.up);
		var input_direction_x = input_pressed(input_source.right) - input_pressed(input_source.left);
		
		var previous_selection = selection;
		switch (state) {
			case states.select_enemy:
				selection = clamp(selection + input_direction_y, 0, array_length(enemies) - 1);
				break;
					
			case states.select_action:
				// Separately, we work on moving through the matrix,
				// strange garbage
				var input_selection_y = selection + input_direction_y * 2;
				if (input_selection_y < 0 || input_selection_y > array_length(actions) - 1) // No portal teleportation
					break;
				
				selection = clamp(input_selection_y, 0, array_length(actions) - 1);
				selection = clamp(selection + input_direction_x, 0, array_length(actions) - 1);
				break;
		}
		
		if (previous_selection != selection) {
			audio_play_sound(snd_ui_selecting, 0, false);
		}
	}
	
	/// @param {Id.Instance} hud
	static draw_menu = function(hud) {
		update_input(hud);
		
		switch (state) {
			case states.select_enemy:
				draw_enemies(hud);
				break;
				
			case states.select_action:
				draw_actions(hud);
				break;
		}
	}
	
	/// @param {Id.Instance} hud
	static draw_enemies = function(hud) {
		var encouter = hud.encouter;
		var arena = hud.arena;
		var enemies = encouter.enemies_instance;
		
		var text_offset_x = hud.text_offset_x;
		var text_offset_y = hud.text_offset_y;
		var text = "";

		for (var i = 0; i < array_length(enemies); i ++) {
			var enemy = enemies[i];
			var bar_draw_x = arena.x - arena.width / 2 + bar_offset_x;
			var bar_draw_y = arena.y - arena.height / 2 + bar_offset_y + 32 * i;

			var name = enemy.name;
		
			// Draw enemy hp bar
			draw_sprite(spr_ui_encouter_menu_bar_background, 0, bar_draw_x + 350, bar_draw_y - 14);
			draw_sprite_field(spr_ui_encouter_menu_bar_hp, 0, bar_draw_x + 350, bar_draw_y - 14, enemy.hp / enemy.hp_max);
		
			// Draw soul & generate text
			if (selection == i) {
				draw_sprite(soul_sprite, 0, bar_draw_x + soul_offset_x, bar_draw_y + soul_offset_y);
				text += "    ";
			} else {
				text += "* ";
			}
				
			text += name + "\n";
		}

		// Draw enemy names
		scribble(text)
			.transform(2, 2, 0)
			.line_height(16, 16)
			.draw(arena.x - arena.width / 2 + text_offset_x, arena.y - arena.height / 2 + text_offset_y);
	}
	
	/// @param {Id.Instance} hud
	static draw_actions = function(hud) {
		var encouter = hud.encouter;
		var arena = hud.arena;
		
		var draw_x = arena.x - arena.width / 2;
		var draw_y = arena.y - arena.height / 2;
		var text_offset_x = hud.text_offset_x;
		var text_offset_y = hud.text_offset_y;

		for (var i = 0; i < array_length(actions); i++) {
			var action = actions[i];
			var render = "";
			var text_x = text_offset_x;
			var text_y = text_offset_y;
		
			render += i == selection ? "    " :  "* ";
	
			if ((i + 1) % 2 == 0) {
				text_x += 260;
			}
		
			text_y += floor(i / 2) * 28;
			render += action.name;
			
			scribble(render)
				.transform(2, 2, 0)
				.draw(draw_x + text_x, draw_y + text_y);
		}
	
		var soul_x = draw_x + soul_offset_x + bar_offset_x + (((selection + 1) % 2 == 0) ? 260 : 0);
		var soul_y = draw_y + soul_offset_y + bar_offset_y+ floor(selection / 2) * 28;
		draw_sprite(soul_sprite, 0, soul_x, soul_y);
	}
}

function EncouterButtonItem() : EncouterButton() constructor {
	self.sprite = engine_encouter_default_button_item_sprite;
	self.soul_offset = -34;
	
	self.selection = 0;
	
	/// @param {Id.Instance} hud
	static update_input = function(hud) {
		var encouter = hud.encouter;
		var player = encouter.player;
		var actions = encouter.mercy_actions;
		
		if (input_pressed(input_source.skip)) {
			close(hud);
		}
		
		if (input_pressed(input_source.select)) {
			var item = encouter.player.items[selection];
			
			item.on_after_use = function(encouter) {
				if (array_length(encouter.player.items) == 0) {
					encouter.input.close();
				}
			}
			
			audio_play_sound(snd_ui_select, 0, false);
			keyboard_clear(keyboard_lastkey);
			selection = 0;
			
			item.use(encouter);
		}
		
		
		if (input_pressed(input_source.left) && selection > 0) {
			audio_play_sound(snd_ui_selecting, 0, false);
			selection--;
		}
	
		if (input_pressed(input_source.right) && selection < array_length(encouter.player.items) - 1) {
			audio_play_sound(snd_ui_selecting, 0, false);
			selection++;
		}
	}
	
	/// @param {Id.Instance} hud
	static draw_menu = function(hud) {
		update_input(hud);
		
		var encouter = hud.encouter;
		var arena = hud.arena;
		var player = encouter.player;
		
		if (array_length(player.items) == 0) return;
		
		var text = "";
	
		for (var i = 0; i < array_length(player.items); i++) {
			if (i != 0) {
				text += "  ";
			}
		
			text += selection == i ? "   " : "*";
		}
	
		var item = player.items[selection];
	
		draw_sprite(spr_ui_encouter_button_soul, 0, arena.x - arena.width / 2 + 28 + 30 * selection, arena.y + arena.height / 2 - 24);
		scribble($"* {item.name}\n  {item.description}\n[c_white]{text}")
			.line_height(16, 16)
			.transform(2, 2, 0)
			.draw(arena.x - arena.width / 2 + 20, arena.y - arena.height / 2 + 10);
	}
	
	/// @param {Id.Instance} input
	/// @return {Bool}
	static avaible = function(input) {
		return input.encouter.player.has_items();
	} 
}


function EncouterButtonMercy() : EncouterButton() constructor {
	self.sprite = engine_encouter_default_button_mercy_sprite;
	self.soul_offset = -38;
	self.soul_sprite = spr_ui_encouter_button_soul;
		
	self.selection = 0;

	/// @param {Id.Instance} hud
	static update_input = function(hud) {
		var encouter = hud.encouter;
		var actions = encouter.mercy_actions;
		
		if (input_pressed(input_source.skip)) {
			close(hud);
		}
		
		if (input_pressed(input_source.select)) {
			actions[selection].invoke(encouter);
			audio_play_sound(snd_ui_select, 0, false);
		}

		if (input_pressed(input_source.up) && selection > 0) {
			audio_play_sound(snd_ui_selecting, 0, false);
			selection--;
		}
	
		if (input_pressed(input_source.down) && selection < array_length(actions) - 1) {
			audio_play_sound(snd_ui_selecting, 0, false);
			selection++;
		}
	}
	
	/// @param {Id.Instance} hud
	static draw_menu = function(hud) {
		update_input(hud);
		
		var encouter = hud.encouter;
		var arena = hud.arena;
		var actions = encouter.mercy_actions;
	
		var text = ""
	
		for (var i = 0; i < array_length(actions); i++) {
			var action = actions[i];
			var name = action.name;
		
			var draw_x = arena.x - arena.width / 2 + 28;
			var draw_y = arena.y - arena.height / 2 + 36 + 32 * i;
		
			if (selection == i) {
				draw_sprite(soul_sprite, 0, draw_x, draw_y - 8);
				text += "    ";
			} else {
				text += "* ";
			}
				
			text += $"{name}\n";
			scribble(text)
				.transform(2, 2, 0)
				.line_height(16, 16)
				.draw(arena.x - arena.width / 2 + 20, arena.y - arena.height / 2 + 10);
		} 
	}
}

