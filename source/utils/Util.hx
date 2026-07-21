package utils;

import haxe.Http;
import flixel.addons.display.FlxBackdrop;
import flixel.input.keyboard.FlxKey;
import backend.NativeFileSystem;

class Util {
	/**
	 * A regex to match valid URLs.
	 */
	public static final URL_REGEX:EReg = ~/^https?:\/?\/?(?:www\.)?[-a-zA-Z0-9@:%_\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$/;

	/**
	 * Sanitizes a URL via a regex.
	 *
	 * @param targetUrl The URL to sanitize.
	 * @return The sanitized URL, or an empty string if the URL is invalid.
	 */
	public static function sanitizeURL(targetUrl:String):String {
		targetUrl = (targetUrl ?? '').trim();
		if (targetUrl == '') return '';

		final lowerUrl:String = targetUrl.toLowerCase();
		if (!lowerUrl.startsWith('http:') && !lowerUrl.startsWith('https:')) targetUrl = 'http://' + targetUrl;
		if (URL_REGEX.match(targetUrl)) return URL_REGEX.matched(0);

		return '';
	}

	/**
	 * Checks for available updates by sending an HTTP request to a remote changelog file.
	 *
	 * The function reads the version and changelog from the response and compares the remote version with the local one.
	 *
	 * The returned array contains:
	 *	[0] The remote version as a string.
	 *	[1] The changelog text.
	 *
	 * Note: This function uses asynchronous HTTP handling but returns the array immediately,
	 * which means the data will not be populated at the time of return.
	 *
	 * @param url Optional URL pointing to the changelog file (defaults to GitHub repository).
	 * @return An array of strings containing the remote version and changelog (data filled after async callback).
	 */
	public static function checkForUpdates(url:String = null):Array<String> {
		if (url == null || url.length == 0)
			url = "https://raw.githubusercontent.com/system32unknown/AlterEngine/main/CHANGELOG.md";

		var returnedData:Array<String> = [];
		var version:String = Main.engineVer;
		if (Settings.data.checkForUpdates) {
			trace('checking for updates...');
			var http:Http = new Http(url);

			http.onData = (data:String) -> {
				var verEndIdx:Int = data.indexOf(';');
				returnedData[0] = data.substring(0, verEndIdx);
				returnedData[1] = data.substring(verEndIdx + 1, data.length); // Extract the changelog after the version number

				var updateVersion:SemanticVersion = returnedData[0];
				trace('version online: $updateVersion, your version: $version');
				if (updateVersion != version) {
					trace('versions arent matching! please update.');
					http.onData = http.onError = null;
					http = null;
				}
			}
			http.onError = (error:String) -> Logs.error('HTTP Error: $error');
			http.request();
		}
		return returnedData;
	}

	inline public static function toBool(value:Dynamic):Null<Bool> {
		if (value is Int || value is Float) return (value >= 1);
		return null;
	}

	/**
	 * Plays a sound safely by checking if it exists or not.
	 *
	 * made to play some sounds in-game with no concerns as to whether it will crash or not.
	 *
	 * this is safer than calling Paths.sound due to an extra check
	 * @param sound  The sound stream (i.e: String, openfl.media.Sound, etc)
	 * @param volume  Sound's volume
	 */
	public static function playSoundSafe(sound:flixel.system.FlxAssets.FlxSoundAsset, volume:Float = 1.0) {
		if (sound != null) FlxG.sound.play(sound, volume);
	}

	/**
	* Reads the contents of a text file from the given path and returns it as an array of strings.
	*
	* On native platforms with MODS_ALLOWED, it uses the file system; otherwise, it reads from embedded assets.
	*
	* The resulting text is split into a list using `listFromString`.
	* @param path The file path or asset path to read from.
	* @return An array of strings derived from the file content, or an empty array if the file doesn't exist or can't be read.
	*/
	public static function readTextFiles(path:String):Array<String> {
		var daList:String = null;
		if (NativeFileSystem.exists(path)) daList = NativeFileSystem.getContent(path);
		return daList == null ? [] : listFromString(daList);
	}

	inline public static function listFromString(string:String):Array<String> {
		return [for (txt in string.trim().split('\n')) txt.trim()];
	}

	/**
	 * Runs platform-specific code to open a URL in a web browser.
	 * @param site The URL to open.
	 * @return Results URL status.
	 */
	public static function browserLoad(site:String):Int {
		site = sanitizeURL(site);
		if (site == '') throw 'Invalid URL: "$site"';

		#if linux
		var cmd:Int = Sys.command("xdg-open", [site]); // generally `xdg-open` should work in every distro
		if (cmd != 0) cmd = Sys.command("/usr/bin/xdg-open", [site]); // run old command JUST IN CASE it fails, which it shouldn't
		return cmd;
		#else
		FlxG.openURL(site);
		return 1;
		#end
	}

	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		return '${FlxG.stage.application.meta.get('company')}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}

	public static function removeDupString(string:Array<String>):Array<String> {
		var tempArray:Array<String> = [];
		var lastSeen:String = '';
		string.sort((a:String, b:String) -> return (a == b) ? 0 : (a > b) ? 1 : -1);
		for (str in string) {
			if (str != lastSeen) tempArray.push(str);
			lastSeen = str;
		}
		return tempArray;
	}

	public static function getColor(value:Dynamic, ?defValue:Array<Int>):FlxColor {
		if (value == null) return FlxColor.WHITE;
		if (value is Int) return value;
		if (value is String) return colorFromString(value);
		if (value is Array) return colorFromArray(value, defValue);
		return FlxColor.WHITE;
	}

	inline public static function colorFromArray(colors:Array<Int>, ?defColors:Array<Int>):FlxColor {
		colors = fixRGBColorArray(colors, defColors);
		return FlxColor.fromRGB(colors[0], colors[1], colors[2], colors[3]);
	}

	inline public static function fixRGBColorArray(colors:Array<Int>, ?defColors:Array<Int>):Array<Int> {
		final endResult:Array<Int> = (defColors != null && defColors.length > 2) ? defColors : [255, 255, 255, 255]; // Red, Green, Blue, Alpha
		for (i in 0...endResult.length) if (colors[i] > -1) endResult[i] = colors[i];
		return endResult;
	}

	public static inline function colorFromString(color:String):FlxColor {
		var hideChars:EReg = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x')) color = color.substring(color.length - (color.length >= 10 ? 8 : 6));

		var colorNum:Null<FlxColor> = FlxColor.fromString(color) ?? FlxColor.fromString('#$color');
		return colorNum ?? FlxColor.WHITE;
	}

	public static inline function createBackDrop(cellW:Int, cellH:Int, w:Int, h:Int, alt:Bool, color1:FlxColor, color2:FlxColor):FlxBackdrop {
		return new FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(cellW, cellH, w, h, alt, color1, color2));
	}

	/**
	 * Recursively reads all files from a directory and its subdirectories.
	 *
	 * Optionally removes the base path from each returned file path.
	 *
	 * Files with `.json` extensions will have the extension removed in the result.
	 *
	 * @param path The root directory path to search.
	 * @param erasePath If true (default), the base path will be removed from the returned file paths.
	 * @return An array of file paths (without `.json` extension), relative or full depending on `erasePath`.
	 */
	public static function recursivelyReadFolders(path:String, ?erasePath:Bool = true):Array<String> {
		var ret:Array<String> = [];
		for (i in FileSystem.readDirectory(path)) returnFileName(i, ret, path);
		if (erasePath) {
			path += '/';
			for (i in 0...ret.length) ret[i] = ret[i].replace(path, '');
		}
		return ret;
	}

	/**
	 * Helper function to recursively traverse a directory tree.
	 *
	 * Adds full file paths to the output list, removing `.json` extensions.
	 *
	 * @param path Current file or folder to evaluate.
	 * @param toAdd The array to which valid file paths are added.
	 * @param full The full base path used to resolve nested directories.
	 */
	static function returnFileName(path:String, toAdd:Array<String>, full:String):Void {
		var fullPath:String = '$full/$path';
		if (FileSystem.isDirectory(fullPath)) {
			for (i in FileSystem.readDirectory(fullPath)) returnFileName(i, toAdd, fullPath);
		} else toAdd.push(fullPath.replace('.json', ''));
	}

	public static inline function inRange(a:Float, b:Float, tolerance:Float):Bool {
		return (a <= b + tolerance && a >= b - tolerance);
	}

	inline public static function changeFramerateCap(newFramerate:Int):Void {
		if (newFramerate > FlxG.updateFramerate) {
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		} else {
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

	inline public static function notBlank(s:String):Bool {
		return s != null && s.length > 0;
	}

	/**
	 * Returns if any key is not being pressed (or just pressed)
	 * @param keyArray An array of FlxKeys
	 * @return Bool True if there's any key in keyArray that isn't being pressed
	 */
	public static function anyNotPressed(keyArray:Array<FlxKey>):Bool {
		var isKeyNotPressed:FlxKey -> Bool = key -> return FlxG.keys.checkStatus(key, RELEASED) || FlxG.keys.checkStatus(key, JUST_RELEASED);
		return Lambda.exists(keyArray, isKeyNotPressed);
	}
	/**
	 * Returns true if all of the keys in keyArray are being pressed,
	 * but also only fires once on the last key in the array being justPressed
	 * @param keyArray An array of FlxKeys
	 * @return Bool True if all of the keys in keyArray are being pressed, with at least one of them being in a JUST_PRESSED state
	 */
	public static function allPressedWithDebounce(keyArray:Array<FlxKey>):Bool {
		return !anyNotPressed(keyArray) && FlxG.keys.anyJustPressed(keyArray);
	}
}