package hotml;

typedef Enumeration = {
	name:String,
	nameId:String,
	body:String
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
