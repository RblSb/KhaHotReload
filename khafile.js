let project = new Project('first_hx_game');

project.addSources('src');
project.addAssets('res/**', {
	nameBaseDir: 'res',
	destination: '{dir}/{name}',
	name: '{dir}/{name}'
});
project.addDefine('kha_no_ogg');
project.addDefine('analyzer-optimize');
project.addParameter('-dce full');
project.targetOptions.html5.disableContextMenu = true;

if (process.argv.includes("--watch")) {
	let libPath = project.addLibrary('hotml');
	project.addDefine('js_classic');
	const path = require('path');
	if (!libPath) libPath = path.resolve('./Libraries/hotml');
	const Server = require(`${libPath}/bin/server.js`).hotml.server.Main;
	const server = new Server(`${path.resolve('.')}/build/${platform}`, 'kha.js');
	callbacks.postHaxeRecompilation = () => {
		server.reload();
	}
	callbacks.postAssetReexporting = (path) => {
		server.reloadAsset(path);
	}
}

resolve(project);
