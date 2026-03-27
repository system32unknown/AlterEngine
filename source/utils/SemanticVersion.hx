package utils;

import macros.GitCommitMacro;

/**
 * Represents a semantic-style game version string.
 *
 * Format: `MAJOR.MINOR.PATCH[-PRERELEASE]`
 *
 * Examples:
 * - `1.0.0`
 * - `1.2.3-beta`
 * - `2.0.0-rc1`
 *
 * Internally stored as a `String` with implicit `from`/`to` conversions.
 * Exposes structured access to each version component via properties,
 * and supports comparison operators (`==`, `>`, `>=`).
 *
 * Comparison follows standard semver precedence:
 * major -> minor -> patch -> prerelease (a stable release is always greater than a prerelease of the same version).
 */
abstract SemanticVersion(String) from String to String {
	/**
	 * Major version number. Incrementing this signals breaking changes.
	 */
	public var major(get, set):Int;

	/**
	 * Minor version number. Incrementing this signals new backwards-compatible features.
	 */
	public var minor(get, set):Int;

	/**
	 * Patch version number. Incrementing this signals backwards-compatible bug fixes.
	 */
	public var patch(get, set):Int;

	/**
	 * Optional prerelease identifier suffix, e.g. `beta`, `rc1`, `alpha-2`.
	 * Returns an empty string if no prerelease tag is present.
	 */
	public var prereleaseId(get, set):String;

	/**
	 * Git commit hash of the current build, generated at compile time.
	 */
	public var COMMIT_HASH(get, never):String;

	function get_COMMIT_HASH():String
		return GitCommitMacro.commitHash;

	/**
	 * Git commit number of the current build, generated at compile time.
	 */
	public var COMMIT_NUM(get, never):Int;

	function get_COMMIT_NUM():Int
		return GitCommitMacro.commitNumber;

	
	inline function get_prereleaseId():String {
		var parts:Array<String> = this.split("-");
		parts.shift();
		return parts.join("-");
	}
	
	inline function set_prereleaseId(id:String):String {
		var base:String = stripPrerelease();
		this = id.length > 0 ? '$base-$id' : base;
		return id;
	}

	inline function stripPrerelease():String
		return this.split("-").shift();
	
	inline function get_major():Int
		return Std.parseInt(stripPrerelease().split(".")[0]) ?? 0;

	inline function get_minor():Int
		return Std.parseInt(stripPrerelease().split(".")[1]) ?? 0;

	inline function get_patch():Int
		return Std.parseInt(stripPrerelease().split(".")[2]) ?? 0;

	inline function set_major(i:Int):Int {
		var pre:String = prereleaseId;
		this = pre.length > 0 ? '$i.$minor.$patch-$pre' : '$i.$minor.$patch';
		return i;
	}

	inline function set_minor(i:Int):Int {
		var pre:String = prereleaseId;
		this = pre.length > 0 ? '$major.$i.$patch-$pre' : '$major.$i.$patch';
		return i;
	}

	inline function set_patch(i:Int):Int {
		var pre:String = prereleaseId;
		this = pre.length > 0 ? '$major.$minor.$i-$pre' : '$major.$minor.$i';
		return i;
	}

	@:op(A == B)
	static function eq(a:SemanticVersion, b:SemanticVersion):Bool
		return a.major == b.major && a.minor == b.minor && a.patch == b.patch && a.prereleaseId == b.prereleaseId;

	/**
	 * Returns true if `a` is strictly greater than `b`.
	 *
	 * Compares components in order: major, minor, patch.
	 * If all numeric components are equal, a stable release (no prerelease tag)
	 * is considered greater than a prerelease. Otherwise, prerelease tags are
	 * compared lexicographically.
	 */
	@:op(A > B)
	static function gt(a:SemanticVersion, b:SemanticVersion):Bool {
		if (a.major != b.major) return a.major > b.major;
		if (a.minor != b.minor) return a.minor > b.minor;
		if (a.patch != b.patch) return a.patch > b.patch;

		final aPre:String = a.prereleaseId;
		final bPre:String = b.prereleaseId;
		if (aPre == '' && bPre != '') return true;
		if (aPre != '' && bPre == '') return false;
		return aPre > bPre;
	}

	/**
	 * Returns true if `a` is greater than or equal to `b`.
	 */
	@:op(A >= B)
	static function gte(a:SemanticVersion, b:SemanticVersion):Bool
		return eq(a, b) || gt(a, b);
}