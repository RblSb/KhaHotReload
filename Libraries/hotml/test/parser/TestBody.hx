package test.parser;

import utest.Assert;
import utest.Test;
import hotml.server.Parser;
import hotml.server.Main;

@:access(hotml.server.Main)
@:access(hotml.server.Parser)
class TestBody extends Test {

	function testMain() {
		final main = new Main("test/js", "TestBody.js");
		main.reload();
		final classes = main.file.classes;
		final klass = classes["backend_Shaders"];
		final methods = klass.methods;
		Assert.equals("backend_Shaders", klass.name);
		Assert.same([], methods["new"].args);
		Assert.equals("", methods["new"].body);

		Assert.same(["fragSource", "maxTextures", "maxIfs"], methods["foo"].args);
		Assert.equals(6, methods["foo"].body.split("\n").length);

		Assert.same([], methods["bar"].args);
		Assert.equals(23, methods["bar"].body.split("\n").length);

		Assert.same([], methods["empty"].args);
		Assert.equals("", methods["empty"].body);
		Assert.same([], methods["empty2"].args);
		Assert.equals(" ", methods["empty2"].body);
		Assert.same([], methods["empty3"].args);
		Assert.equals("", methods["empty3"].body);
		Assert.same([], methods["empty4"].args);
		Assert.equals("/*Hi*/", methods["empty4"].body);
		Assert.same([], methods["empty5"].args);
		Assert.equals("foo()", methods["empty5"].body);
	}

}
