package debug;

// crash handler stuff
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import lime.system.System;

/**
 * Global crash handler for capturing and logging uncaught errors.
 *
 * This class hooks into both native (C++/HL) and OpenFL error systems
 * to ensure crashes are properly logged and reported.
 */
class CrashHandler {
	/**
	 * Initializes the crash handler.
	 *
	 * Sets up platform-specific error handlers and registers
	 * an OpenFL uncaught error listener.
	 */
	public static function init():Void {
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
		FlxG.stage.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorOFL);
	}

	/**
	 * Handles OpenFL uncaught errors.
	 *
	 * Extracts a readable error message from the event and forwards
	 * it to the main error handler.
	 *
	 * @param e The uncaught error event.
	 */
	static function onErrorOFL(e:UncaughtErrorEvent):Void {
		var message:String = '';
		if (Std.isOfType(e.error, Error)) {
			var err:Error = cast(e.error, Error);
			message = err.getStackTrace() ?? err.message;
		} else if (Std.isOfType(e.error, ErrorEvent)) message = cast(e.error, ErrorEvent).text;
		else message = Std.string(e.error);

		e.preventDefault();
		e.stopImmediatePropagation();

		onError(message);
	}

	/**
	 * Main crash handler logic.
	 *
	 * The report is saved to the `./crash/` directory and displayed
	 * to the user before exiting the application.
	 *
	 * @param message The error message or stack trace.
	 */
	static function onError(message:String):Void {
		final path:String = './crash/${FlxG.stage.application.meta.get('file')}_${Date.now().toString().replace(" ", "_").replace(":", "'")}.txt';
		final defines:Map<String, Dynamic> = macros.DefinesMacro.defines;

		var errMsg:String = getError();
		errMsg += '\nPlatform: ${System.platformLabel} ${System.platformVersion} [Target: ${scripting.ScriptUtils.getTarget()}]';
		errMsg += '\nFlixel Current State: ${Type.getClassName(Type.getClass(FlxG.state))}';
		errMsg += '\nUncaught Error: $message\nPlease report this error to the GitHub page: https://github.com/system32unknown/AlterEngine\n\nCustom Crash Handler written by: sqirra-rng and Codename Engine Team and Altertoriel';
		errMsg += '\nHaxe: ${defines['haxe']} / Flixel: ${defines['flixel']} / OpenFL: ${defines['openfl']} / Lime: ${defines['lime']}';
		if (Mods.currentModDirectory != '') errMsg += '\nCurrent Active Mod: ${Mods.currentModDirectory}';

		try {
			if (!FileSystem.exists("./crash/")) FileSystem.createDirectory("./crash/");
			File.saveContent(path, errMsg);

			Sys.println("\n" + errMsg);
			Sys.println('Crash dump saved in ${haxe.io.Path.normalize(path)}');
		} catch (e:Dynamic) Sys.println('Error!\nCouldn\'t save the crash dump because:\n$e');

		utils.system.NativeUtil.showMessageBox("Alter Engine Crash Handler", errMsg, MSG_ERROR);
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		System.exit(1);
	}

	/**
	 * Builds a formatted stack trace string from the current exception stack.
	 *
	 * Iterates through the call stack and formats each entry
	 * into a human-readable format.
	 *
	 * @return A formatted stack trace string.
	 */
	static function getError():String {
		var error:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(p, file, line, column):
					switch (p) {
						case Method(cla, func): error += '[$file] ${cla.split(".")[cla.split(".").length - 1]}.$func() - (line $line)';
						case _: error += '$file (line $line)';
					}
					if (column != null) error += ':$column';
				case CFunction: error += "Non-Haxe (C) Function";
				case Module(c): error += 'Module $c';
				case Method(cl, m): error += '$cl - $m';
				case LocalFunction(v): error += 'Local Function $v';
				default: Sys.println(stackItem);
			}
			error += '\n';
		}
		return error;
	}
}