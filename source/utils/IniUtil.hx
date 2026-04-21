package utils;

typedef IniSection = Map<String, String>;
typedef IniMap = Map<String, IniSection>;

class IniUtil {
	// Compiled once, reused across calls
	static final RE_SECTION:EReg = ~/^\s*\[([^\]]+)\]\s*$/;
	static final RE_KEYVAL:EReg = ~/^\s*([^#;=\s][^=]*?)\s*=\s*(.*?)\s*$/;
	static final RE_QUOTED:EReg = ~/^(["'])(.*)\1$/;
	static final RE_COMMENT:EReg = ~/\s+[#;].*$/;

	public static inline function parseAsset(assetPath:String):IniMap
		return parseString(Paths.getTextFromFile(assetPath));

	/**
	 * Parse an INI string and return a fresh IniMap. 
	 */
	public static function parseString(data:String):IniMap {
		var map:IniMap = [];
		parseStringToMap(map, data);
		return map;
	}

	/**
	 * Parse an INI string into an existing IniMap, merging values.
	 */
	public static function parseStringToMap(map:IniMap, data:String):Void {
		var currentSection:IniSection = getOrCreateSection(map, "Global");

		for (rawLine in data.split('\n')) {
			// Normalise Windows line endings
			final line:String = rawLine.rtrim().split('\r').join('');

			if (line.length == 0 || line.charAt(0) == '#' || line.charAt(0) == ';') continue;

			if (RE_SECTION.match(line)) currentSection = getOrCreateSection(map, RE_SECTION.matched(1).trim());
			else if (RE_KEYVAL.match(line)) currentSection.set(RE_KEYVAL.matched(1), unquote(stripInlineComment(RE_KEYVAL.matched(2))));
		}
	}

	/**
	 * Serialise an IniMap back to an INI-formatted string.
	 */
	public static function toString(map:IniMap):String {
		final buf:StringBuf = new StringBuf();
		var first:Bool = true;

		for (sectionName => section in map) {
			if (!first) buf.add('\n');
			first = false;

			if (sectionName != "Global") buf.add('[$sectionName]\n');
			for (key => value in section) buf.add('$key = $value\n');
		}
		return buf.toString();
	}

	static inline function getOrCreateSection(map:IniMap, name:String):IniSection {
		var section:IniSection = map.get(name);
		if (section == null) {
			section = [];
			map.set(name, section);
		}
		return section;
	}

	/**
	 * Strip an unquoted trailing inline comment, e.g. `foo  ; comment` → `foo` 
	 */
	static inline function stripInlineComment(s:String):String {
		return RE_QUOTED.match(s) ? s : RE_COMMENT.replace(s, '');
	}

	/**
	 * Remove surrounding matching quote characters, if present.
	 */
	static inline function unquote(s:String):String {
		return RE_QUOTED.match(s) ? RE_QUOTED.matched(2) : s;
	}
}