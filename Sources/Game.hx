package;

import kha.Canvas;
import kha.System;
import khm.Screen;
import khm.Screen.Pointer;

class Game extends Screen {
	final rects:Array<Rect> = [];
	final rects2:Array<Rect2> = [];

	public function init() {}

	override function onUpdate():Void {
		for (r in rects) r.update();
		for (r in rects2) r.update();
	}

	override function onRender(canvas:Canvas):Void {
		final g = canvas.g2;
		g.begin(true, 0xff505050);
		for (r in rects) {
			g.color = r.color;
			g.fillRect(r.x, r.y, r.size, r.size);
		}
		for (r in rects2) {
			g.color = Rect2.color;
			g.drawRect(r.x, r.y, r.size, r.size);
		}
		g.end();
	}

	override function onMouseDown(p:Pointer): Void {
		if (p.type == 1) {
			rects.resize(0);
			rects2.resize(0);
			return;
		}
		switch (Std.random(2)) {
			case 0: rects.push(new Rect());
			case 1: rects2.push(new Rect2());
		}
	}

}

class Rect {

	// public var color = 0xFFFF0000;
	public var color = 0xFFFFFF00;
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

class Rect2 {

	public static var color = 0xFF00FF00;
	public var x = Std.random(System.windowWidth());
	public var y = Std.random(System.windowHeight());
	var sideX = Std.random(2) == 0;
	var sideY = Std.random(2) == 0;
	public final size = 20;

	public function new() {
		// trace(123);
	}

	public function update():Void {
		if (sideX) x++; else x--;
		if (sideY) y++; else y--;
		if (x > System.windowWidth() - size) sideX = false;
		if (y > System.windowHeight() - size) sideY = false;
		if (x < 0) sideX = true;
		if (y < 0) sideY = true;
	}

}
