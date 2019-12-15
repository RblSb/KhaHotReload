package rects;

import kha.System;

class Rect3 {

	public var color = 0xFFC088D1;
	public var x = Std.random(System.windowWidth());
	public var y = Std.random(System.windowHeight());
	var sideX = Std.random(2) == 0;
	var sideY = Std.random(2) == 0;
	public final size = 20;

	public function new() {}

	public function update():Void {
		if (sideX) x++; else x--;
		if (sideY) y++; else y--;
		if (x > System.windowWidth() - size) sideX = false;
		if (y > System.windowHeight() - size) sideY = false;
		if (x < 0) sideX = true;
		if (y < 0) sideY = true;
	}

}
