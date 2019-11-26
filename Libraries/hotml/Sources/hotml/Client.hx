package hotml;

import js.html.WebSocket;
import js.Browser;
import haxe.Json;

typedef Func = {
	name:String,
	args:Array<String>,
	body:String,
	?isStatic:Bool
}

typedef Klass = {
	name:String,
	?nameId:String,
	?parent:String,
	?interfaces:String,
	methods:Map<String, Func>,
	staticVars:Map<String, String>
}

typedef Enumeration = {
	name:String,
	nameId:String,
	body:String
}

typedef Patch = {
	type:String,
	// classes
	?klass:Klass,
	// enums
	?enumeration:Enumeration,
	// fields
	?className:String,
	?name:String,
	?value:String,
	// constructor
	?classId:String,
	// functions
	?func:Func,
	// assets
	?path:String,
	?data:String
}

class Client {

	var isConnected = false;

	public function new(?host:String, port = 3220) {
		if (host == null) host = Browser.location.hostname;
		if (host == "") host = "localhost";
		try {
			final ws = new WebSocket('ws://$host:$port');
			ws.onmessage = onMessage;
			ws.onopen = () -> {
				trace("Connected to hot-reload server");
				isConnected = true;
			}
			ws.onerror = (e:String) -> {
				trace('Error: $e');
				isConnected = false;
			}
			ws.onclose = () -> {
				trace("Closed");
			}
		} catch (e:Any) {
			trace(e);
		}
		// ws.send(JSON.stringify(obj));
	}

	function onMessage(e) {
		var arr:Array<Patch> = Json.parse(e.data);
		for (obj in arr) {
			trace('Event: ${obj.type}');
			switch (obj.type) {
				case "addClass":
					addClass(obj.klass);
				case "staticVar":
					setStaticVar(obj.className, obj.name, obj.value);
				case "constructor":
					setConstructor(obj.classId, obj.className, obj.func);
				case "func":
					setFunction(obj.className, obj.func);
				case "addEnum":
					setEnum(obj.enumeration);
				case "reloadAsset":
					#if kha
					Kha.reloadAsset(obj.path, obj.data);
					#else
					trace("Asset reloader not found");
					#end
			}
		}
	}

	function getFuncMap(data:Dynamic):Map<String, Func> {
		final map:Map<String, Func> = [];
		for (field in Reflect.fields(data.h)) {
			map.set(field, Reflect.field(data.h, field));
		}
		return map;
	}

	function getStringMap(data:Dynamic):Map<String, String> {
		final map:Map<String, String> = [];
		for (field in Reflect.fields(data.h)) {
			map.set(field, Reflect.field(data.h, field));
		}
		return map;
	}

	function addClass(klass:Klass):Void {
		final name = klass.nameId;
		final methods = getFuncMap(klass.methods);
		final staticVars = getStringMap(klass.staticVars);
		// final interfaces = klass.interfaces;

		addConstructor(klass.name, name, methods["new"]);
		untyped $hxClasses[name].prototype = {};
		for (func in methods) {
			if (func.name == "new") continue;
			setFunction(name, func);
		}
		if (klass.parent != null) {
			untyped $hxClasses[name].prototype = $extend(
				$hxClasses[klass.parent].prototype, $hxClasses[name].prototype
			);
		}

		for (key in staticVars.keys()) {
			setStaticVar(name, key, staticVars[key]);
		}
	}

	function addConstructor(classId:String, className:String, func:Func):Void {
		untyped window[classId] = $hxClasses[className] = makeFunc(func);
	}

	function setConstructor(classId:String, className:String, func:Func):Void {
		#if !js_classic
		trace("Constructor patching unsupported without js_classic define");
		untyped if (window[classId] == null) window[classId] = {};
		#end
		final obj:Dynamic = {};
		// backup and restore fields and prototype
		copyObjectFields(untyped window[classId], obj);
		final proto = untyped window[classId].prototype;
		addConstructor(classId, className, func);
		if (proto != null) untyped window[classId].prototype = proto;
		copyObjectFields(obj, untyped window[classId]);
	}

	function copyObjectFields(from:{}, to:{}):Void {
		untyped __js__("{
			for (var key in {0}) {
				if (Object.prototype.hasOwnProperty.call({0}, key)) {
					{1}[key] = {0}[key];
				}
			}
		}", from, to);
	}

	function setFunction(className:String, func:Func):Void {
		if (func.isStatic) untyped $hxClasses[className][func.name] = makeFunc(func);
		else untyped $hxClasses[className].prototype[func.name] = makeFunc(func);
	}

	function setStaticVar(className:String, name:String, value:String):Void {
		untyped $hxClasses[className][name] = value;
	}

	function makeFunc(func:Func):js.lib.Function {
		#if js_classic
		return untyped __js__("new Function(...{0}, {1})", func.args, func.body);
		#end
		var args = "";
		if (func.args.length > 0) args += func.args[0];
		for (i in 1...func.args.length) args += "," + func.args[i];
		final code = '(function ($args) {${func.body}})';
		return untyped __js__("eval({0})", code);
	}

	function makeObj(code:String):js.lib.Object {
		final code = '({$code})';
		return untyped __js__("eval({0})", code);
	}

	function setEnum(en:Enumeration):Void {
		untyped $hxEnums[en.nameId] = makeObj(en.body);
	}

}
