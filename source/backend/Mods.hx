package backend;

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

private typedef ModEntry = {folder:String, enabled:Bool};

class Mods {
	public static var currentModDirectory:String = '';
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'awards'
	];

	static var globalMods:Array<String> = [];

	inline public static function getGlobalMods():Array<String>
		return globalMods;

	inline public static function pushGlobalMods():Array<String> {
		globalMods = [];
		for (mod in parseList().enabled) {
			var pack:Dynamic = getPack(mod);
			if (pack != null && pack.runsGlobally) globalMods.push(mod);
		}
		return globalMods;
	}

	inline public static function getActiveModDirectories(lowercase:Bool = false):Array<String> {
		var list:Array<String> = [];
		final path:String = 'modsList.txt';

		var remaining:Array<String> = getModDirectories(true);
		if (remaining.length <= 0 || !FileSystem.exists(path)) return list;

		var lines:Array<String> = Util.readTextFiles(path);
		for (i in 0...lines.length) {
			if (remaining.length <= 0) break;
			if (lines.length > 0 && lines[0].length > 0) {
				var parts:Array<String> = lines[i].split('|');
				var modLower:String = parts[0].toLowerCase();

				if (remaining.contains(modLower) && parts[1] == '1') {
					remaining.remove(modLower);
					list.push(lowercase ? modLower : parts[0]);
				}
			}
		}

		remaining = null;
		return list;
	}

	inline public static function getModDirectories(lowercase:Bool = false):Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = Paths.mods();

		if (!FileSystem.exists(modsFolder)) return list;

		for (folder in FileSystem.readDirectory(modsFolder)) {
			var path:String = haxe.io.Path.join([modsFolder, folder]);
			var lower:String = folder.toLowerCase();

			if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(lower) && !list.contains(lower))
				list.push(lowercase ? lower : folder);
		}

		return list;
	}

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String, allowDuplicates:Bool = false):Array<String> {
		if (defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if (paths.contains(defaultPath)) {
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
			for (value in Util.readTextFiles(file))
				if (value.length > 0 && (allowDuplicates || !mergedList.contains(value)))
					mergedList.push(value);

		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true):Array<String> {
		var found:Array<String> = [];

		inline function tryAdd(p:String):Void
			if (FileSystem.exists(p) && !found.contains(p))
				found.push(p);

		// Main folder
		tryAdd(path + fileToFind);

		// Week folder
		if (Paths.currentLevel != null && Paths.currentLevel != path)
			tryAdd(Paths.getFolderPath(fileToFind, Paths.currentLevel));

		#if MODS_ALLOWED
		if (mods) {
			// Global mods first
			for (mod in getGlobalMods())
				tryAdd(Paths.mods('$mod/$fileToFind')); // Then "PsychEngine/mods/" main folder

			tryAdd(Paths.mods(fileToFind));

			if (currentModDirectory != null && currentModDirectory.length > 0)
				tryAdd(Paths.mods('$currentModDirectory/$fileToFind')); // And lastly, the loaded mod's folder
		}
		#end

		return found;
	}

	public static function getPack(?folder:String):Dynamic {
		#if MODS_ALLOWED
		if (folder == null) folder = currentModDirectory;

		var path:String = Paths.mods('$folder/pack.json');
		if (FileSystem.exists(path)) {
			try {
				var raw:String = NativeFileSystem.getContent(path);
				if (raw != null && raw.length > 0) return tjson.TJSON.parse(raw);
			} catch (e:Dynamic) Logs.error('ERROR: $e');
		}
		#end
		return null;
	}

	public static var updatedOnState:Bool = false;

	public static function parseList():ModsList {
		if (!updatedOnState) updateModList();

		var list:ModsList = {enabled: [], disabled: [], all: []};
		try {
			for (mod in Util.readTextFiles('modsList.txt')) {
				if (mod.trim().length < 1) continue;

				var parts:Array<String> = mod.split("|");
				list.all.push(parts[0]);
				if (parts[1] == "1") list.enabled.push(parts[0]);
				else list.disabled.push(parts[0]);
			}
		} catch (e:Dynamic) Logs.error('ERROR: $e');
		return list;
	}

	static function updateModList():Void {
		#if MODS_ALLOWED
		// Find all that are already ordered
		var entries:Array<ModEntry> = [];
		var added:Array<String> = [];

		try {
			for (mod in Util.readTextFiles('modsList.txt')) {
				var parts:Array<String> = mod.split("|");
				var folder:String = parts[0].trim();
				if (folder.length > 0 && !added.contains(folder) && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder))) {
					added.push(folder);
					entries.push({folder: folder, enabled: parts[1] == "1"});
				}
			}
		} catch (e:Dynamic) Logs.error('ERROR: $e');

		// Append newly discovered mod folders as enabled
		for (folder in getModDirectories()) {
			if (folder.trim().length > 0 && !added.contains(folder)) {
				added.push(folder);
				entries.push({folder: folder, enabled: true});
			}
		}

		// Now save file
		var fileStr:String = '';
		for (values in entries) {
			if (fileStr.length > 0) fileStr += '\n';
			fileStr += values.folder + '|' + (values.enabled ? '1' : '0');
		}

		File.saveContent('modsList.txt', fileStr);
		updatedOnState = true;
		#end
	}

	public static function loadTopMod():Void {
		currentModDirectory = '';

		#if MODS_ALLOWED
		var enabled:Array<String> = parseList().enabled;
		if (enabled != null && enabled.length > 0) currentModDirectory = enabled[0];
		#end
	}
}