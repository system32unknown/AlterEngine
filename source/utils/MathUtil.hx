package utils;

/**
 * Utilities for performing mathematical operations.
 */
@:nullSafety
class MathUtil {
	/**
	 * Rounds a floating-point number down to a specified number of decimal places.
	 * @param value The number to round down.
	 * @param decimals The number of decimal places.
	 * @return The rounded down number.
	 */
	public static function floorDecimal(value:Float, precision:Float = 2):Float {
		value *= (precision = Math.pow(10, precision));
		return Math.floor(value) / precision;
	}

	/**
	 * Returns an array containing the minimum and maximum of two given values.
	 * @param v1 The first value.
	 * @param v2 The second value.
	 * @return An array where the first element is the minimum and the second is the maximum.
	 */
	inline public static function getMinAndMax(v1:Float, v2:Float):Array<Float> {
		return [Math.min(v1, v2), Math.max(v1, v2)];
	}

	/**
	 * Linearly interpolates between two values with an optional exponent for easing.
	 * @param a The start value.
	 * @param b The end value.
	 * @param m The interpolation factor (0 to 1).
	 * @param e The exponent to apply for easing. Default is 1 (linear interpolation).
	 * @return The interpolated value with applied easing.
	 */
	inline public static function interpolate(a:Float, b:Float, m:Float, e:Float = 1):Float {
		m = FlxMath.bound(m, 0, 1);
		return FlxMath.lerp(a, b, Math.pow(m, e));
	}

	/**
	 * Normalizes a given value `x` within the range [`min`, `max`] to a value between 0 and 1.
	 *
	 * @param x			The input value to normalize.
	 * @param min		The minimum value of the range.
	 * @param max		The maximum value of the range.
	 * @param isBound	If true (default), clamps the result to stay within [0, 1]. If false, the result may fall outside this range.
	 * @return			The normalized value of `x`, optionally clamped between 0 and 1.
	 */
	inline public static function normalize(x:Float, min:Float, max:Float, isBound:Bool = true):Float {
		return isBound ? FlxMath.bound((x - min) / (max - min), 0, 1) : (x - min) / (max - min);
	}

	/**
	 * Calculates the mean (average) of a list of float values.
	 * Zero values are skipped in the summation, but still included in the count,
	 * which may result in an inaccurate average if many zeros are present.
	 *
	 * @param values An array of Float values.
	 * @return The arithmetic mean of the values, or 0.0 if the array is empty.
	 */
	public static function mean(values:Array<Float>):Float {
		if (values.length == 0) return 0.0;

		final amount:Int = values.length;
		var result:Float = 0.0;

		var value:Float = 0;
		for (i in 0...amount) {
			value = values[i];
			if (value == 0) continue;
			result += value;
		}

		return result / amount;
	}

	/**
	 * Fast inverse square root approximation.
	 * 
	 * This function approximates 1 / sqrt(x) using the famous "fast inverse square root" 
	 * algorithm popularized by Quake III Arena. It uses bit-level manipulation to quickly 
	 * estimate the result, followed by one iteration of Newton-Raphson refinement.
	 * 
	 * @param x The input value to compute the inverse square root of
	 * @return An approximation of 1 / sqrt(x)
	 */
	public static function invSqrt(x:Float):Float {
		var xt:Int = Std.int(x);
		var half:Float = x * .5;
		var i:Int = xt;
		i = 0x5f3759df - (i >> 1);
		var xt:Float = cast(i);
		return xt * (1.5 - (half * xt * xt));
	}

	/**
	 * Snap a value to another if it's within a certain distance (inclusive).
	 *
	 * Helpful when using functions like `smoothLerpPrecision` to ensure the value actually reaches the target.
	 *
	 * @param base The base value to conditionally snap.
	 * @param target The target value to snap to.
	 * @param threshold Maximum distance between the two for snapping to occur.
	 *
	 * @return `target` if `base` is within `threshold` of it, otherwise `base`.
	 */
	public static function snap(base:Float, target:Float, threshold:Float):Float {
		return Math.abs(base - target) <= threshold ? target : base;
	}

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpPrecision(base, target, deltaTime, halfLife, 0.5)`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param halfLife Time in seconds to reach halfway to `target`.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpDecay(base:Float, target:Float, deltaTime:Float, halfLife:Float):Float {
		if (deltaTime == 0) return base;
		if (base == target) return target;
		return FlxMath.lerp(target, base, Math.pow(2, (-deltaTime / halfLife)));
	}

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpDecay(base, target, deltaTime, -duration / logBase(2, precision))`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param duration Time in seconds to reach `target` within `precision`, relative to the original distance.
	 * @param precision Relative target precision of the interpolation. Defaults to 1% distance remaining.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float {
		if (deltaTime == 0) return base;
		if (base == target) return target;
		return FlxMath.lerp(target, base, Math.pow(precision, deltaTime / duration));
	}

	/**
	 * GCD stands for Greatest Common Divisor
	 * It's used in FullScreenScaleMode to prevent weird window resolutions from being counted as wide screen since those were causing issues positioning the game
	 * It returns the greatest common divisor between m and n
	 *
	 * think it's from hxp..?
	 * @param m
	 * @param n
	 * @return Int the common divisor between m and n
	 */
	public static function gcd(m:Int, n:Int):Int {
		m = Math.floor(Math.abs(m));
		n = Math.floor(Math.abs(n));
		var t:Int;
		do {
			if (n == 0) return m;
			t = m;
			m = n;
			n = t % m;
		} while (true);
	}
}
