package;

using StringTools;

enum abstract JsType(Int) {
	var Classic;
	var Es5;
}

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

enum abstract ParseMode(Int) {
	var ParseRegular;
	var ParseMethods;
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


class Parser {

	public static var logTypes = false;
	public static var logBodies = false;
	public static var logSkips = false;
	final classes:Map<String, Klass> = [];
	final enums:Map<String, Enumeration> = [];

	// checks is js generated without js_classic define
	final matchClosure = ~/\(function \(.*"use strict";/;
	// checks if js generated with js_classic define
	final matchExportsObj = ~/var \$hx_exports =/;
	// matches: var foo_bar = $hx_exports["foo"]["Bar"] = function() {
	// (hx_exports block optional on both constructor types)
	final matchConstructor = ~/^var ([^ ]+) =.* function\((.*)\) {( };)?$/;
	// matches: var foo_bar = $hxClasses["foo.Bar"] = function() {
	final matchClassicConstructor = ~/^var ([^ ]+) = \$hxClasses\["([^ ]+)"\] =.* function\((.*)\) {( };)?$/;
	// empty class without constructor
	// (hx_exports block optional on both obj types)
	final matchObj = ~/var ([^ ]+) =.*{ ?}/;
	// matches: var foo_bar = $hxClasses["foo.Bar"] = {};
	final matchClassicObj = ~/^var ([^ ]+) = \$hxClasses\["([^ ]+)"\] =.*{ ?};$/;
	// internal name for client array access
	final matchClassNameId = ~/\$hxClasses\["(.+)"] = (.+);/;
	final matchParent = ~/__super__ = (.+);/;
	final matchInterfaces = ~/__interfaces__ = (.+);/;
	// matches: Foo.bar = "some stuff";
	final matchStaticVar = ~/^([^[ .]+)\.([^ .]+) = (.+);/;
	// Generated functions from: var arr = [for (i in 0...10) i];
	final matchStaticArr = ~/^([^ ]+)\.([^ ]+) = \(function\(\$this\)/;
	final matchStaticFunc = ~/^([^ ]+)\.([^ ]+) = function\((.*)\)/;
	final matchFunc = ~/([^ ,\t]+): function\((.*)\)/;
	// matches: var some_bar = $hxEnums["foo.Bar"]
	final matchEnum = ~/var ([^ []+) = \$hxEnums\["([^"]+)/;
	var mode = ParseMode.ParseRegular;
	var currentClass:Klass;
	final lines:Array<String>;
	var num = 0;
	var jsType = JsType.Classic;
	var jsTypeDetected = false;

	public function new(file:String) {
		lines = file.split("\n");
		num = 0;
		while(num < lines.length) {
			final line = lines[num];
			// trace(line);
			switch (mode) {
				case ParseRegular:
					parseRegular(line);
				case ParseMethods:
					parseMethods(line);
			}
			num++;
		}
	}

	public function getJsType():String {
		final s = switch jsType {
			case Classic: "Classic";
			case Es5: "Es5";
		}
		return s + (!jsTypeDetected ? " (Undetected)" : "");
	}

	inline function traceType(s:String):Void {
		if (Parser.logTypes) trace(s);
	}

	inline function traceBody(s:String):Void {
		if (Parser.logBodies) trace(s);
	}

	inline function traceSkip(s:String):Void {
		if (Parser.logSkips) trace(s);
	}

	function parseRegular(line:String):Void {
		if (!jsTypeDetected && matchClosure.match(line)) {
			jsTypeDetected = true;
			jsType = Es5;
			return;
		}
		if (!jsTypeDetected && matchExportsObj.match(line)) {
			jsTypeDetected = true;
			jsType = Classic;
			return;
		}
		if (jsType == Es5 && matchConstructor.match(line)) {
			final name = matchConstructor.matched(1);
			final args = matchConstructor.matched(2).split(",");
			setConstructor(name, args);
			return;
		}
		if (jsType == Classic && matchClassicConstructor.match(line)) {
			final name = matchClassicConstructor.matched(1);
			final nameId = matchClassicConstructor.matched(2);
			final args = matchClassicConstructor.matched(3).split(",");
			setConstructor(name, args);
			setNameId(name, nameId);
			return;
		}
		if (matchParent.match(line)) {
			final parent = matchParent.matched(1);
			if (classes[parent] == null) {
				traceSkip('Skip ${currentClass.name} parent $parent');
				return;
			}
			currentClass.parent = classes[parent].nameId;
			return;
		}
		if (matchInterfaces.match(line)) {
			currentClass.interfaces = matchInterfaces.matched(1);
			return;
		}
		if (line.endsWith(".prototype = {") ||
			line.contains(".prototype = $extend(")) {
			traceType('${currentClass.name} {');
			mode = ParseMethods;
			return;
		}
		if (jsType == Es5 && matchObj.match(line)) {
			final name = matchObj.matched(1);
			setObj(name);
			return;
		}
		if (jsType == Classic && matchClassicObj.match(line)) {
			final name = matchClassicObj.matched(1);
			final nameId = matchClassicObj.matched(2);
			setObj(name);
			setNameId(name, nameId);
			return;
		}
		if (matchClassNameId.match(line)) {
			final nameId = matchClassNameId.matched(1);
			final name = matchClassNameId.matched(2);
			setNameId(name, nameId);
			return;
		}
		if (matchStaticVar.match(line)) {
			final className = matchStaticVar.matched(1);
			final field = matchStaticVar.matched(2);
			final value = matchStaticVar.matched(3);
			if (field == "__name__") return;
			if (value.startsWith("function")) {
				throw "TODO one-line function";
			}
			traceType('$className.$field = ${minString(value)}');
			classes[className].staticVars[field] = value;
			return;
		}
		if (matchStaticArr.match(line)) {
			final className = matchStaticArr.matched(1);
			final field = matchStaticArr.matched(2);
			final value = readFunctionBody("}(this));");
			traceType('$className.$field = $value');
			classes[className].staticVars[field] = value;
			return;
		}
		if (matchStaticFunc.match(line)) {
			final className = matchStaticFunc.matched(1);
			final name = matchStaticFunc.matched(2);
			final args = matchStaticFunc.matched(3);
			final body = readFunctionBody();
			if (className == "window") return;
			traceType('$className.$name($args) {${body.split("\n").length}}');
			traceBody(body);
			classes[className].methods[name] = {
				name: name,
				args: args.split(","),
				body: body,
				isStatic: true
			};
			return;
		}
		if (matchEnum.match(line)) {
			final name = matchEnum.matched(1);
			final nameId = matchEnum.matched(2);
			final body = readFunctionBody();
			enums[name] = {name: name, nameId: nameId, body: body};
			return;
		}
	}

	function setConstructor(name:String, args:Array<String>):Void {
		final constructor:Func = {
			name: "new",
			args: args,
			body: readFunctionBody()
		};
		final klass:Klass = {
			name: name,
			methods: ["new" => constructor],
			staticVars: []
		};
		traceType('$name($args).new {${constructor.body.split("\n").length}}');
		traceBody(constructor.body);
		classes[name] = klass;
		currentClass = klass;
	}

	function setObj(name:String):Void {
		final klass:Klass = {
			name: name,
			methods: [],
			staticVars: []
		};
		traceType('Class $name {}');
		classes[name] = klass;
	}

	function setNameId(name:String, nameId:String):Void {
		if (classes[name] == null) {
			traceSkip('Skip $name id $nameId');
			return;
		}
		classes[name].nameId = nameId;
	}

	function readFunctionBody(lastLine = "};"):String {
		final body = new StringBuf();
		var isOpened = false;
		var level = 0;
		while (num < lines.length) {
			final line = lines[num];
			var lineStart = 0;
			var lineEnd = line.length;
			for (i in 0...line.length) {
				final code = line.fastCodeAt(i);
				if (code == "{".code) {
					if (level == 0) {
						lineStart = i + 1;
						isOpened = true;
					}
					level++;
				}
				else if (code == "}".code) {
					level--;
					if (isOpened && level == 0) {
						lineEnd = i - 1;
						break;
					}
				}
			}
			if (body.length > 0 && lineStart == 0 && lineEnd == line.length) body.add("\n");
			body.add(line.substring(lineStart, lineEnd));
			if (isOpened && level == 0) break;
			num++;
		}
		return body.toString();
	}

	function parseMethods(line:String):Void {
		if (matchFunc.match(line)) {
			final name = matchFunc.matched(1);
			final args = matchFunc.matched(2);
			final body = readFunctionBody("	}");
			traceType('function $name($args) {${body.split("\n").length}}');
			traceBody(body);
			currentClass.methods[name] = {
				name: name,
				args: args.split(","),
				body: body
			};
			return;
		}
		if (line == "};" || line == "});") {
			traceType('} (${currentClass.name})');
			mode = ParseRegular;
		}
	}

	public function makeDiffTo(file:Parser):Array<Patch> {
		final result:Array<Patch> = [];
		for (klass in file.classes) compareClass(klass, result);
		for (en in file.enums) compareEnum(en, result);
		return result;
	}

	function compareClass(klass:Klass, result:Array<Patch>):Void {
		final className = klass.nameId;
		final old = classes[klass.name];
		if (old == null) {
			trace('New class: $className');
			result.push({type: "addClass", klass: klass});
			return;
		}
		if (old.parent != klass.parent) {
			trace('$className: new parent: ${klass.parent}');
			result.push({type: "addClass", klass: klass});
			return;
		}
		final keys = mergeKeys(old.staticVars, klass.staticVars);
		for (key in keys) {
			final value = old.staticVars[key];
			final newValue = klass.staticVars[key];
			if (value != newValue) {
				trace('$className: static var $key value: ${minString(newValue)}');
				result.push({type: "staticVar", className: className, name: key, value: newValue});
			}
		}
		final keys = mergeKeys(old.methods, klass.methods);
		for (key in keys) {
			final value = old.methods[key];
			var newValue = klass.methods[key];
			if ('$value' != '$newValue') {
				trace('$className: func $key() value: ${minString("" + newValue)}');
				if (newValue == null) newValue = {
					name: value.name, args: [], body: "", isStatic: value.isStatic
				};
				if (newValue.name == "new") {
					result.push({type: "constructor", classId: klass.name, className: className, func: newValue});
				} else {
					result.push({type: "func", className: className, func: newValue});
				}
			}
		}
	}

	function compareEnum(en:Enumeration, result:Array<Patch>):Void {
		final enumName = en.nameId;
		final old = enums[en.name];
		if (old == null) {
			trace('New enum: $enumName');
			result.push({type: "addEnum", enumeration: en});
			return;
		}
		if (old.body != en.body) {
			trace('New enum body: ${minString(en.body)}');
			result.push({type: "addEnum", enumeration: en});
			return;
		}
	}

	function mergeKeys<T>(map:Map<String, T>, map2:Map<String, T>):Array<String> {
		final result:Array<String> = [];
		for (key in map.keys()) result.push(key);
		for (key in map2.keys())
			if (result.indexOf(key) == -1) result.push(key);
		return result;
	}

	function minString(s:String):String {
		if (s == null) return "null";
		if (s.length < 23) return s;
		return s.substr(0, 10) + "..." + s.substr(s.length - 10, 10);
	}

}
