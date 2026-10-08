package utils;

import haxe.io.Path;

/**
 * Utilties for interpreting command line arguments.
 */
@:nullSafety
class CLIUtil {
	/**
	 * If we don't do this, dragging and dropping a file onto the executable
	 * causes it to be unable to find the assets folder.
	 */
	public static function resetWorkingDir():Void {
		#if sys
		var cwd:String = Path.addTrailingSlash(Sys.getCwd());
		var gameDir:String = '';
		#if mac
		gameDir = Path.addTrailingSlash(Path.join([Path.directory(Sys.programPath()), '../Resources/']));
		#else
		gameDir = Path.addTrailingSlash(Path.directory(Sys.programPath()));
		#end
		if (cwd == gameDir) {
			trace('Working directory is already correct.');
		} else {
			trace('Changing working directory from ${Sys.getCwd()} to $gameDir');
			Sys.setCwd(gameDir);
		}
		#end
	}

	public static function processArgs():Array<String> {
		return #if sys interpretArgs(cleanArgs(Sys.args())) #else [] #end;
	}

	static function interpretArgs(args:Array<String>):Array<String> {
		var result:Array<String> = [for (arg in args) arg]; // Copy the array.

		while (args.length > 0) {
			var arg:Null<String> = args.shift();
			if (arg == null) continue;

			if (arg.startsWith('-')) {
				switch (arg) {
					// Flags
					case '-h' | '--help':
						printUsage();
						Sys.exit(0);
					case '-ver' | '--version': trace(Main.engineVer);
					case "-nocolor": Main.noTerminalColor = true;
					case "-v" | "-verbose" | "--verbose": Main.verbose = true;
				}
			} else {
				Sys.println('Unknown command: $arg');
				printUsage();
			}
		}

		return result;
	}

	static function printUsage():Void {
		Sys.println("-- Alter Engine Command Line help --");
		Sys.println("-help / -h	| Show this help");
		Sys.println("-nocolor | Disables colors in the terminal");
		Sys.println("-v / -verbose | Enables verbose logging");
		Sys.println("-ver / -version | Displays current of engine version");
	}

	/**
	 * Clean up the arguments passed to the application before parsing them.
	 * @param args The arguments to clean up.
	 * @return The cleaned up arguments.
	 */
	static function cleanArgs(args:Array<String>):Array<String> {
		var result:Array<String> = [];
		if (args == null || args.length == 0) return result;

		return args.map(function(arg:String):String {
			if (arg == null) return '';
			return arg.trim();
		}).filter((arg:String) -> return arg != null && arg != '');
	}
}