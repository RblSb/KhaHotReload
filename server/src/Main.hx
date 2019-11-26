package;

import sys.io.File;
import haxe.crypto.Base64;
import haxe.Json;
import js.Node.process;
import js.npm.ws.Server as WSServer;
import js.npm.ws.WebSocket;

@:keep
@:expose
class Main {

	// static function main() new Main();
	public static var logResult = false;
	final buildDir:String;
	final scriptName:String;
	final wss:WSServer;
	final clients:Array<WebSocket> = [];

	public function new(buildDir:String, scriptName:String, port = 3220) {
		this.buildDir = buildDir;
		this.scriptName = scriptName;
		wss = new WSServer({port: port});
		function exit() {
			process.exit();
		}
		process.on('exit', exit);
		process.on('SIGINT', exit); // ctrl+c
		// process.on('uncaughtException', (log) -> {
		// 	trace(log);
		// });
		// process.on('unhandledRejection', (reason, promise) -> {
		// 	trace('Unhandled Rejection at:', reason);
		// });
		wss.on('connection', onConnect);
	}

	function onConnect(ws:WebSocket) {
		trace('Client connected');
		clients.push(ws);

		var reply = {
			type: "connect",
			id: 0, // id in array
			clients: [],
			diff: ""
		};
		ws.send(Json.stringify(reply), null);

		ws.on('message', function(data) {
			// message(ws, data);
		});
		ws.on('close', function(err) {
			trace('Client disconnected');
			clients.remove(ws);
			// removeClient(ws);
		});
	}

	function broadcast(data):Void {
		for (client in clients) client.send(Json.stringify(data), null);
	}

	var file:Parser;

	public function reload():Void {
		// Parser.logTypes = true;
		// Parser.logBodies = true;
		// Parser.logSkips = true;
		final data = File.getContent('$buildDir/$scriptName');
		if (file == null) {
			file = new Parser(data);
			trace('$buildDir/$scriptName cached');
			trace('Js type: ${file.getJsType()}');
			return;
		}
		final newFile = new Parser(data);
		final arr = file.makeDiffTo(newFile);
		if (logResult) trace(arr);
		broadcast(arr);
		file = newFile;
	}

	public function reloadAsset(path:String):Void {
		final bytes = File.getBytes('$buildDir/$path');
		final data = Base64.encode(bytes);
		broadcast([{type:"reloadAsset", path: path, data: data}]);
	}

}
