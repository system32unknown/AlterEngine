package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * A build macro that generates a switch-based dynamic function dispatch expression,
 * similar to `Reflect.callMethod`, but with statically unrolled argument counts.
 *
 * Produces a `switch` on `argsName.length` with a case for each argument count from `0` to
 * `totalArgs` (inclusive), each calling `funcName` with the corresponding number of
 * positional arguments unpacked from the `argsName` array.
 * Throws `"Too many arguments"` if the array length exceeds `totalArgs`.
 *
 * Example output for `totalArgs = 2`, `funcName = "fn"`, `argsName = "args"`:
 * ```haxe
 * switch (args.length) {
 * 	case 0: fn();
 * 	case 1: fn(args[0]);
 * 	case 2: fn(args[0], args[1]);
 * 	case 3: fn(args[0], args[1], args[2]);
 * 	default: throw "Too many arguments";
 * }
 * ```
 *
 * @param totalArgs The maximum number of arguments to support (the macro increments this by 1 internally).
 * @param funcName  The name of the function identifier to call in each generated case.
 * @param argsName  The name of the array identifier from which arguments are unpacked.
 */
class ReflectMacro {
	macro public static function generateReflectionLike(totalArgs:Int, funcName:String, argsName:String):Expr {
		#if macro
		totalArgs++;

		var funcCalls:Array<Expr> = [];
		for (i in 0...totalArgs) {
			var args:Array<Expr> = [for (d in 0...i) macro $i{argsName}[$v{d}]];
			funcCalls.push(macro $i{funcName}($a{args}));
		}

		return {
			pos: Context.currentPos(),
			expr: ESwitch(macro($i{argsName}.length), [
				for (i in 0...totalArgs) {
					values: [macro $v{i}],
					expr: funcCalls[i],
					guard: null,
				}
			], macro throw "Too many arguments")
		};
		#end
	}
}
