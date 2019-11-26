package hotml;

import kha.Assets;
import haxe.io.Path;
import haxe.crypto.Base64;
import kha.Image;

class Kha {

	public static function reloadAsset(path:String, base64:String):Void {
		final ext = Path.extension(path);
		var name = Path.withoutExtension(path);
		name = ~/(-|\/)/g.replace(name, "_");
		final data = Base64.decode(base64);
		switch (ext) {
			case "png", "jpg", "hdr":
				// Assets.loadImageFromPath(path, false, (img) -> {
				Image.fromEncodedBytes(data, ext, (img) -> {
					final current = Assets.images.get(name);
					if (current == null) {
						Assets.loadImage(name, (img) -> {});
						return;
					}
					untyped current.image = img.image;
					untyped current.texture = img.texture;
					untyped current.myWidth = img.myWidth;
					untyped current.myHeight = img.myHeight;
				}, (e) -> trace(e));
			case "mp3", "wav", "ogg", "flac":
			case "mp4":
			case "ttf":
			default:
				if (ext.length > 0) name += '_$ext';
				final blob = Assets.blobs.get(name);
				if (blob == null) {
					Assets.loadBlob(name, (blob) -> {});
					return;
				}
				@:privateAccess blob.bytes = data;
		}
	}

}
