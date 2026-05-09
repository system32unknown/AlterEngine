package backend;

import openfl.media.Sound;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;

#if !desktop
import haxe.io.Path;
#end

/**
 * A cross-platform file system abstraction that works on paths relative to the
 * game's root directory. Non-modded assets are resolved via OpenFL's asset
 * system; paths that start with "mods" are resolved against the real file
 * system so that user-supplied content can be loaded at runtime.
 */
class NativeFileSystem {
	/**
	 * Populated at startup with every path registered in the OpenFL asset manifest.
	 */
	public static var openFlAssets:Array<String> = null;

	/**
	 * Returns the text content of a file, or `null` if it cannot be found.	
	 */
	public static function getContent(path:String):Null<String> {
		if (!isModded(path)) return openFlAssets.contains(path) ? Assets.getText(path) : null;

		var sys_path:String = getPathLike(path);
		return sys_path != null ? File.getContent(sys_path) : null;
	}

	/**
	 * Returns a `BitmapData` for the given path, or `null` if it cannot be found.	
	 */
	public static function getBitmap(path:String):Null<BitmapData> {
		if (!isModded(path)) {
			if (openFlAssets.contains(path)) return OpenFlAssets.getBitmapData(path);
			return null;
		}

		var sys_path:String = getPathLike(path);
		return sys_path != null ? BitmapData.fromFile(sys_path) : null;
	}

	/**
	 * Returns a `Sound` for the given path, or `null` if it cannot be found.
	 */
	public static function getSound(path:String):Null<Sound> {
		if (!isModded(path)) {
			if (openFlAssets.contains(path))
				return OpenFlAssets.getSound(path);
			return null;
		}

		var sys_path:String = getPathLike(path);
		return sys_path != null ? Sound.fromFile(sys_path) : null;
	}

	/**
	 * Returns `true` if the given path points to an existing file or directory.
	 */
	public static function exists(path:String):Bool {
		if (!isModded(path)) {
			if (openFlAssets.contains(path)) return true;
			return openFlAssets.filter(p -> p.startsWith(path)).length > 0;
		}

		return getPathLike(path) != null;
	}

	/**
	 * Lists the immediate children of a directory. Returns an empty array if not found.
	 */
	public static function readDirectory(directory:String):Array<String> {
		if (!isModded(directory)) {
			var dirs:Array<String> = readOpenFlDirectory(directory);
			if (dirs.length > 0) return dirs;
		}

		var testdir:String = getPathLike(directory);
		return testdir != null ? FileSystem.readDirectory(testdir) : [];
	}

	/**
	 * Returns `true` when the given path is a directory (rather than a file).
	 * @param directory A path **relative** to the working directory.
	 */
	public static function isDirectory(directory:String):Bool {
		if (!isModded(directory)) return openFlAssets.filter(p -> p.startsWith(directory) && p != directory).length > 0;

		return FileSystem.isDirectory(addCwd(directory));
	}

	/**
	 * Returns `true` when the path belongs to a mod (rather than a built-in asset).
	 */
	static inline function isModded(path:String):Bool
		return path.startsWith("mods");

	/**
	 * Builds the child list for a non-modded (OpenFL) virtual directory.
	 */
	static function readOpenFlDirectory(directory:String):Array<String> {
		var dirs:Array<String> = [];
		var prefix:String = directory.endsWith("/") ? directory : directory + "/";

		for (dir in openFlAssets.filter(p -> p.startsWith(prefix))) {
			@:privateAccess
			for (library in Assets.libraries.keys()) {
				var libKey:String = '$library:$dir';
				if (library != "default" && Assets.exists(libKey)) {
					if (!dirs.contains(libKey) && !dirs.contains(dir)) dirs.push(libKey);
				} else if (Assets.exists(dir) && !dirs.contains(dir)) {
					// Return only the file name, not the full path
					var name:Null<String> = dir.split("/").pop();
					if (name != null && name != "") dirs.push(name);
				}
			}
		}

		return dirs;
	}

	/**
	 * Prepends the current working directory to a relative path.
	 * On desktop targets the path is returned unchanged (the CWD is already
	 * the game root); on other targets the real CWD is prepended.
	 */
	static function addCwd(directory:String):String {
		#if desktop
		return directory;
		#else
		var cwd:String = Path.removeTrailingSlashes(Sys.getCwd());
		if (directory.startsWith(cwd)) return directory;
		return Path.addTrailingSlash(cwd) + directory;
		#end
	}

	#if linux
	/**
	 * Returns the real path of a file that is *similar* to the given one,
	 * performing a case-insensitive search on each path component.
	 * For example `"mod/firelight"` will match `"Mod/FireLight"` on disk.
	 *
	 * @param path The path to resolve (relative or absolute).
	 * @return The first matching real path, or `null` if nothing was found.
	 */
	public static function getPathLike(path:String):Null<String> {
		var absPath:String = addCwd(path);
		if (FileSystem.exists(absPath)) return absPath;

		// Walk backwards from the end of the path until we reach a directory
		// that actually exists, then do a case-insensitive scan from there.
		var parts:Array<String> = absPath.replace("\\", "/").split("/");
		var pending:Array<String> = [];

		while (parts.length > 0 && !FileSystem.exists(parts.join("/")))
			pending.insert(0, parts.pop());

		return findFile(parts.join("/"), pending);
	}

	/**
	 * Recursively resolves each component in `keys` against `basePath` using
	 * a case-insensitive directory scan at each level.
	 */
	static function findFile(basePath:String, keys:Array<String>):Null<String> {
		var current:String = basePath;
		for (part in keys) {
			if (part == "") continue;

			var match:String = findNode(current, part);
			if (match == null) return null;

			current = current + "/" + match;
		}
		return current;
	}

	/**
	 * Returns the real name of a file or directory inside `dir` whose name
	 * matches `key` case-insensitively, or `null` if nothing is found.
	 */
	static function findNode(dir:String, key:String):Null<String> {
		try {
			var lower:String = key.toLowerCase();
			for (entry in FileSystem.readDirectory(dir)) {
				if (entry.toLowerCase() == lower) return entry;
			}
			return null;
		} catch (e:Dynamic) return null;
	}
	#else

	/**
	 * On case-insensitive file systems (Windows, macOS) a straight existence
	 * check is sufficient — the OS handles case folding for us.
	 *
	 * @param path The path to resolve.
	 * @return The real path, or `null` if the file does not exist.
	 */
	public static function getPathLike(path:String):Null<String> {
		var cwd_path:String = addCwd(path);
		return FileSystem.exists(cwd_path) ? cwd_path : null;
	}
	#end
}