## KhaHotReload

![gif demo](https://i.imgur.com/dlB0x9Q.gif)

Code patching without project rebuilding. Supported targets:
- html5
- debug-html5 (Electron)
- krom? (not tested)

You can download this sample and test with VSCode (select and run `HTML5-watch`), or use CLI:
```shell
node Kha/make html5 --server &
node Kha/make html5 --watch
```

### Setup for personal project
- Copy `Libraries/hotml` folder to your project folder.
- Add `#if hotml new hotml.client.Client(); #end` at start of `Main.main()`.
- Add this block to `khafile.js` (before `resolve(project);`):
```js
if (process.argv.includes("--watch")) { // run only in watch mode
	project.targetOptions.html5.unsafeEval = true; // allow eval in electron
	let libPath = project.addLibrary('hotml'); // client code for code-patching
	project.addDefine('js_classic'); // to support constructors patching, optional
	// start websocket server that will send type diffs to client
	const path = require('path');
	if (!libPath) libPath = path.resolve('./Libraries/hotml');
	const Server = require(`${libPath}/bin/server.js`).hotml.server.Main;
	// path to target build folder and main js file.
	const server = new Server(`${path.resolve('.')}/build/${platform}`, 'kha.js');
	callbacks.postHaxeRecompilation = () => {
		server.reload(); // parse js file every compilation
	}
	// for assets reloading
	callbacks.postAssetReexporting = (path) => {
		server.reloadAsset(path);
	}
}
```

Done. For VSCode you also need to copy `.vscode/` launch option and tasks.

### Debug hot-reload server
`Libraries/hotml` is separated VSCode project with personal build task for server side.
`Parser.hx` has some static vars for detected types tracing.

### Usage for other frameworks / pure Haxe projects

This khamake plugin does not depend on Kha ecosystem, except for khamake's file watcher and `postHaxeRecompilation` callback, so you can use it as NodeJS app with any other build system. The only requirements is watch mode for js target and such callback.

### Thanks

To [Robert Konrad](https://github.com/RobDangerous) with initial idea and implementation in [Krom](https://github.com/Kode/Krom) and [KodeGarden](https://github.com/Kode/KodeGarden).
