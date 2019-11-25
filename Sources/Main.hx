package;

import kha.System;
import kha.Assets;
import khm.Screen;
#if kha_html5
import kha.Macros;
import js.html.CanvasElement;
import js.Browser.document;
import js.Browser.window;
#end

class Main {

	public static function main() {
		#if hotml new hotml.Client(); #end
		setFullWindowCanvas();
		System.start({title: "Kha", width: 800, height: 600}, (_) -> {
			 //Just loading everything is ok for small projects
			Assets.loadEverything(() -> {
				final game = new Game();
				game.show();
				game.init();
			});
		});
	}

	static function setFullWindowCanvas():Void {
		#if kha_html5
		//make html5 canvas resizable
		document.documentElement.style.padding = "0";
		document.documentElement.style.margin = "0";
		document.body.style.padding = "0";
		document.body.style.margin = "0";
		var canvas:CanvasElement = cast document.getElementById(Macros.canvasId());
		canvas.style.display = "block";
		var resize = function() {
			canvas.width = Std.int(window.innerWidth * window.devicePixelRatio);
			canvas.height = Std.int(window.innerHeight * window.devicePixelRatio);
			canvas.style.width = document.documentElement.clientWidth + "px";
			canvas.style.height = document.documentElement.clientHeight + "px";
		}
		window.onresize = resize;
		resize();
		#end
	}

}
