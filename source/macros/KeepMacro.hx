package macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

/**
 * Macro utilities for HScript-heavy projects.
 *
 * Ensures commonly-used packages are included for DCE/reflection, while explicitly excluding
 * platforms/tools/editor-only packages that cause issues or bloat.
 */
class KeepMacro {
	public static function keep():Void {
		final excludes:Array<String> = [
			"flixel.addons.editors.spine",
			"flixel.addons.nape",
			"flixel.system.macros",

			"haxe.macro",
			#if (js || hxcpp) "haxe.atomic.AtomicObject", #end

			"lime._internal.backend.air",
			"lime._internal.backend.html5",
			"lime._internal.backend.kha",
			"lime.tools",
		];

		final compathx4:Array<String> = [
			"sys.db.Sqlite",
			"sys.db.Mysql",
			"sys.db.Connection",
			"sys.db.ResultSet",
			"haxe.remoting.Proxy",
		];

		if (Context.defined("sys") && !Context.defined("hl")) {
			for (inc in ["sys", "openfl.net"]) Compiler.include(inc, compathx4);
		}

		for (inc in [
			// FLIXEL
			"flixel", "lime", "haxe", "openfl", "funkin.vis",
			#if VIDEOS_ALLOWED "hxvlc", #end
			#if (desktop && DISCORD_ALLOWED) "hxdiscord_rpc", #end
			"hscript",
			// OTHER LIBRARIES & STUFF
			#if cpp "cpp", #end
			#if sys "sys", #end
			"json2object",
			// BASE PATH LIBRARIES THAT DOESN'T INCLUDE
			"backend", "shaders", "objects", "utils", "effects",
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf"
		]) Compiler.include(inc, true, excludes);
	}
}
#end