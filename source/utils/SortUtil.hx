package utils;

import flixel.util.FlxSort;
import flixel.FlxBasic;

@:nullSafety
class SortUtil {
	public static function byStrumTime(Obj1:Dynamic, Obj2:Dynamic):Int {
		if (Obj1 == null || Obj2 == null) return 0;
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public static inline function byZIndex(order:Int, a:FlxBasic, b:FlxBasic):Int {
		if (a == null && b == null) return 0;
		if (a == null) return order;
		if (b == null) return -order;
		return FlxSort.byValues(order, a.zIndex, b.zIndex);
	}

	/**
	 * Sort predicate for sorting strings alphabetically.
	 * @param a The first string to compare.
	 * @param b The second string to compare.
	 * @return 1 if `a` comes before `b`, -1 if `b` comes before `a`, 0 if they are equal
	 */
	public static inline function alphabetically(a:String, b:String):Int {
		return a == b ? 0 : a > b ? 1 : -1; // Sort alphabetically. Yes that's how this works.
	}

	public static function uppercaseAlphabetically(a:String, b:String):Int {
		a = a.toUpperCase();
		b = b.toUpperCase();

		return alphabetically(a, b);
	}
}