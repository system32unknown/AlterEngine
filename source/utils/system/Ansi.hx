package utils.system;

enum abstract AnsiStyle(Int) from Int to Int {
	public var RESET:AnsiStyle = 0; // 0m
	public var BOLD:AnsiStyle = 1; // 1m
	public var DIM:AnsiStyle = 2; // 2m
	public var ITALIC:AnsiStyle = 3; // 3m
	public var UNDERLINE:AnsiStyle = 4; // 4m
	public var BLINK:AnsiStyle = 5; // 5m
	public var BLINK_FAST:AnsiStyle = 6; // 6m
	public var REVERSE:AnsiStyle = 7; // 7m
	public var HIDDEN:AnsiStyle = 8; // 8m
	public var STRIKETHROUGH:AnsiStyle = 9; // 9m
}

enum abstract AnsiColor(Int) from Int to Int {
	public var NONE:AnsiColor = -1;

	public var BLACK:AnsiColor = 0;
	public var DARKBLUE:AnsiColor = 1;
	public var DARKGREEN:AnsiColor = 2;
	public var DARKCYAN:AnsiColor = 3;
	public var DARKRED:AnsiColor = 4;
	public var DARKMAGENTA:AnsiColor = 5;
	public var DARKYELLOW:AnsiColor = 6;
	public var LIGHTGRAY:AnsiColor = 7;
	public var GRAY:AnsiColor = 8;
	public var BLUE:AnsiColor = 9;
	public var GREEN:AnsiColor = 10;
	public var CYAN:AnsiColor = 11;
	public var RED:AnsiColor = 12;
	public var MAGENTA:AnsiColor = 13;
	public var YELLOW:AnsiColor = 14;
	public var WHITE:AnsiColor = 15;
}

@:nullSafety
class Ansi {
	// Index 0..15 maps to ANSI SGR codes (foreground)
	static final ANSI_FG:Array<Int> = [
		30, // BLACK
		34, // DARKBLUE
		32, // DARKGREEN
		36, // DARKCYAN
		31, // DARKRED
		35, // DARKMAGENTA
		33, // DARKYELLOW
		37, // LIGHTGRAY
		90, // GRAY
		94, // BLUE
		92, // GREEN
		96, // CYAN
		91, // RED
		95, // MAGENTA
		93, // YELLOW
		97 // WHITE
	];

	// Index 0..15 maps to OpenFL/Flixel ARGB colors
	static final FLX_COLOR:Array<FlxColor> = [
		0xFF000000, // BLACK
		0xFF000088, // DARKBLUE
		0xFF008800, // DARKGREEN
		0xFF008888, // DARKCYAN
		0xFF880000, // DARKRED
		0xFF880088, // DARKMAGENTA
		0xFF888800, // DARKYELLOW
		0xFFBBBBBB, // LIGHTGRAY
		0xFF888888, // GRAY
		0xFF0000FF, // BLUE
		0xFF00FF00, // GREEN
		0xFF00FFFF, // CYAN
		0xFFFF0000, // RED
		0xFFFF00FF, // MAGENTA
		0xFFFFFF00, // YELLOW
		0xFFFFFFFF // WHITE
	];

	static function idx(c:AnsiColor):Int return (c:Int);

	/**
	 * Convert to ANSI SGR foreground code (30-37,90-97).
	 * Returns 39 (default foreground) for NONE/invalid.
	 */
	public static function colorToANSI(color:AnsiColor):Int {
		var i:Int = Std.int(color);
		return (i >= 0 && i < ANSI_FG.length) ? ANSI_FG[i] : 39; // 39 = default fg
	}

	/**
	 * Convert to FlxColor.
	 * Returns WHITE for NONE/invalid.
	 */
	public static function colorToOpenFL(color:AnsiColor):FlxColor {
		var i:Int = Std.int(color);
		return (i >= 0 && i < FLX_COLOR.length) ? FLX_COLOR[i] : 0xFFFFFFFF;
	}

	public static function style(text:String, s:AnsiStyle, reset:Bool = true):String {
		var prefix:String = '\x1b[${(s:Int)}m';
		return reset ? (prefix + text + '\x1b[0m') : (prefix + text);
	}

	/**
	 * Wrap a string in an ANSI color code.
	 * Example output: "\x1b[31mHello\x1b[0m"
	 */
	public static function wrap(text:String, color:AnsiColor, reset:Bool = true):String {
		if (color == AnsiColor.NONE) return text;
		var prefix:String = '\x1b[${colorToANSI(color)}m';
		return reset ? (prefix + text + '\x1b[0m') : (prefix + text);
	}
}