let project = new Project('first_hx_game');

project.addSources('Sources');
project.addDefine('kha_no_ogg');
project.addDefine('analyzer-optimize');
project.addParameter('-dce full');
project.targetOptions.html5.disableContextMenu = true;

if (process.argv.includes("--watch")) {
	project.addLibrary('khot');
	project.addDefine('js_classic');
	const path = require('path');
	const Server = new require(path.resolve('./server/bin/server.js')).Main;
	const server = new Server(`${path.resolve('.')}/build/${platform}`, 'kha.js');
	callbacks.postHaxeRecompilation = () => {
		server.reload();
	};
}

resolve(project);
