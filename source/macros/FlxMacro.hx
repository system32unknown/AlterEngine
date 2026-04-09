package macros;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

@:nullSafety
class FlxMacro {
	/**
	 * A macro to be called targeting the `FlxBasic` class.
	 * @return An array of fields that the class contains.
	 */
	public static macro function buildZindex():Array<Field> {
		var pos:Position = Context.currentPos();
		
		var cls:haxe.macro.Type.ClassType = Context.getLocalClass().get(); // The FlxBasic class. We can add new properties to this class.
		var fields:Array<Field> = Context.getBuildFields(); // The fields of the FlxClass.

		var hasZIndex:Bool = false;
		for (f in fields) {
			if (f.name == "zIndex") {
				hasZIndex = true;
				break;
			}
		}

		if (!hasZIndex) {
			// Here, we add the zIndex attribute to all FlxBasic objects.
			// This has no functional code tied to it, but it can be used as a target value
			// for the FlxTypedGroup.sort method, to rearrange the objects in the scene.
			fields.push({
				name: "zIndex", // Field name.
				access: [Access.APublic], // Access level
				kind: FieldType.FVar(macro:Int, macro $v{0}), // Variable type and default value
				pos: pos, // The field's position in code.
			});
		}

		return fields;
	}

	public static function initMacros():Void {
		if (Context.defined("hscript_imporved") && !Context.defined("hscript")) haxe.macro.Compiler.define("hscript");
	}
}
#end