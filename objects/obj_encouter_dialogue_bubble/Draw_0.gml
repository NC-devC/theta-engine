draw_self();
scribble($"[c_black]{dialogue[dialogue_index]}")
	.wrap(image_xscale * 56 - 26)
	.line_height(14, 14)
	.draw(x + sprite_edge_left + 20, y + sprite_edge_top + 4, typist);
