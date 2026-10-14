package utils.tools;

/**
 * A static extension which provides utility functions for Arrays.
 */
@:nullSafety
class ArrayTools {
	/**
	 * Return true only if both arrays contain the same elements (possibly in a different order).
	 * @param a The first array to compare.
	 * @param b The second array to compare.
	 * @return Weather both arrays contain the same elements.
	 */
	public static function isEqualUnordered<T>(a:Array<T>, b:Array<T>):Bool {
		if (a.length != b.length) return false;
		for (element in a) if (!b.contains(element)) return false;
		for (element in b) if (!a.contains(element)) return false;
		return true;
	}

	/**
	 * Returns true if `superset` contains all elements of `subset`.
	 * @param superset The array to query for each element.
	 * @param subset The array containing the elements to query for.
	 * @return Weather `superset` contains all elements of `subset`.
	 */
	public static function isSuperset<T>(superset:Array<T>, subset:Array<T>):Bool {
		// Shortcuts.
		if (subset.length == 0) return true;
		if (subset.length > superset.length) return false;

		// Check each element.
		for (element in subset) if (!superset.contains(element)) return false;
		return true;
	}

	/**
	 * Like `join` but adds a word before the last element.
	 * @param array The array to join.
	 * @param separator The separator to use between elements.
	 * @param andWord The word to use before the last element.
	 * @return The joined string.
	 */
	public static function joinPlural(array:Array<String>, separator:String = ', ', andWord:String = 'and'):String {
		if (array.length == 0) return '';
		if (array.length == 1) return array[0];
		return '${array.slice(0, array.length - 1).join(separator)} $andWord ${array[array.length - 1]}';
	}
}