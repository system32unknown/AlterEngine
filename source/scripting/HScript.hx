package scripting;

import flixel.FlxBasic;
import lime.app.Application;
#if HSCRIPT_ALLOWED
import alterhscript.AlterHscript;
import hscript.Expr.Error as AlterError;
import hscript.Printer;
import haxe.ValueException;

typedef HScriptInfos = {
	> haxe.PosInfos,
	var ?funcName:String;
	var ?showLine:Null<Bool>;
}

class HScript extends AlterHscript {
	public var filePath:String;
	public var modFolder:String;
	public var returnValue:Dynamic;

	public var origin:String;
	public override function new(?parent:Dynamic, file:String = '', ?varsToBring:Any = null, ?manualRun:Bool = false) {
		filePath = file;
		if (filePath != null && filePath.length > 0 && parent == null) {
			this.origin = filePath;
			#if MODS_ALLOWED
			var myFolder:Array<String> = filePath.split('/');
			if ('${myFolder[0]}/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}

		var scriptThing:String = file;
		var scriptName:String = null;
		if (parent == null && file != null) {
			var f:String = file.replace('\\', '/');
			if (f.contains('/') && !f.contains('\n')) {
				scriptThing = File.getContent(f);
				scriptName = f;
			}
		}
		super(scriptThing, new alterhscript.AlterConfig(scriptName, false, false));

		preset();
		this.varsToBring = varsToBring;
		if (!manualRun) {
			try {
				var ret:Dynamic = execute();
				returnValue = ret;
			} catch (e:AlterError) {
				returnValue = null;
				this.destroy();
				throw e;
			}
		}
	}

	var varsToBring(default, set):Any = null;

	function getDefaultVariables():Map<String, Dynamic> {
		return [
			"Type" => Type,
			"Sys" => Sys,
			"Date" => Date,
			"DateTools" => DateTools,
			"Reflect" => Reflect,
			"HScript" => HScript,
			"Xml" => Xml,
			"EReg" => EReg,
			"Lambda" => Lambda,

			// Sys related stuff
			#if sys
			"File" => File,
			"FileSystem" => FileSystem,
			#end
			"Assets" => openfl.Assets,

			// OpenFL & Lime related stuff
			"Application" => Application,
			"window" => Application.current.window,

			// Flixel related stuff
			"FlxG" => FlxG,
			"FlxSprite" => FlxSprite,
			"FlxBasic" => FlxBasic,
			"FlxCamera" => FlxCamera,
			"PsychCamera" => backend.PsychCamera,
			"FlxTween" => FlxTween,
			"FlxEase" => FlxEase,
			"FlxPoint" => getClassHSC('flixel.math.FlxPoint'),
			"FlxAxes" => getClassHSC('flixel.util.FlxAxes'),
			"FlxColor" => getClassHSC('flixel.util.FlxColor'),
			"FlxKey" => getClassHSC('flixel.input.keyboard.FlxKey'),
			"FlxSound" => FlxSound,
			"FlxAssets" => flixel.system.FlxAssets,
			"FlxMath" => FlxMath,
			"FlxGroup" => flixel.group.FlxGroup,
			"FlxTypedGroup" => FlxTypedGroup,
			"FlxSpriteGroup" => FlxSpriteGroup,
			"FlxTypeText" => flixel.addons.text.FlxTypeText,
			"FlxText" => FlxText,
			"FlxTimer" => FlxTimer,

			// Engine related stuff
			"Countdown" => backend.BaseStage.Countdown,
			"PlayState" => PlayState,
			"Note" => objects.Note,
			"CustomSubstate" => CustomSubstate,
			"NoteSplash" => objects.NoteSplash,
			"HealthIcon" => objects.HealthIcon,
			"StrumLine" => objects.StrumNote,
			"Character" => objects.Character,
			"Paths" => Paths,
			"Conductor" => Conductor,
			"Alphabet" => Alphabet,
			"DeltaTrail" => effects.DeltaTrail,
			#if AWARDS_ALLOWED
			"Awards" => Awards,
			#end

			"Util" => Util,
			"Settings" => Settings,

			// Backward Support
			"CoolUtil" => Util,
			"ClientPrefs" => Settings,

			#if (!flash && sys)
			"FlxRuntimeShader" => flixel.addons.display.FlxRuntimeShader,
			"ErrorHandledRuntimeShader" => shaders.ErrorHandledShader.ErrorHandledRuntimeShader,
			#end
			'ShaderFilter' => openfl.filters.ShaderFilter,

			"version" => Main.engineVer,
			"engine" => {
				app_version: Application.current.meta.get('version'),
				commit: macros.GitCommitMacro.commitNumber,
				hash: macros.GitCommitMacro.commitHash.trim(),
				name: "Alter Engine"
			}
		];
	}

	override function preset() {
		super.preset();
		parser.preprocessorValues = getDefaultPreprocessors();
		for (key => type in getDefaultVariables()) set(key, type);

		// Functions & Variables
		var music_variables:Map<String, Dynamic> = MusicBeatState.getVariables();
		set('setVar', (name:String, value:Dynamic) -> {
			music_variables.set(name, value);
			return value;
		});
		set('getVar', (name:String) -> {
			if (music_variables.exists(name)) return music_variables.get(name);
			return null;
		});
		set('removeVar', (name:String) -> {
			if (music_variables.exists(name)) {
				music_variables.remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', (text:String, ?color:FlxColor = FlxColor.WHITE) -> PlayState.instance.addTextToDebug(text, color));

		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if (modName == null) {
				if (this.modFolder == null) {
					AlterHscript.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', this.interp.posInfos());
					return null;
				}
				modName = this.modFolder;
			}
			return ScriptUtils.getModSetting(saveTag, modName);
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', (name:String) -> return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', (name:String) -> return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', (name:String) -> return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			return switch (name) {
				case 'left': Controls.justPressed('note_left');
				case 'down': Controls.justPressed('note_down');
				case 'up': Controls.justPressed('note_up');
				case 'right': Controls.justPressed('note_right');
				default: Controls.justPressed(name);
			}
		});
		set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			return switch (name) {
				case 'left': Controls.pressed('note_left');
				case 'down': Controls.pressed('note_down');
				case 'up': Controls.pressed('note_up');
				case 'right': Controls.pressed('note_right');
				default: Controls.pressed(name);
			}
		});
		set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			return switch (name) {
				case 'left': Controls.released('note_left');
				case 'down': Controls.released('note_down');
				case 'up': Controls.released('note_up');
				case 'right': Controls.released('note_right');
				default: Controls.released(name);
			}
		});

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if (libPackage.length > 0) str = '$libPackage.';
				set(libName, Type.resolveClass(str + libName));
			} catch (e:AlterError) AlterHscript.error(Printer.errorToString(e, false), this.interp.posInfos());
		});
		set("openState", (name:String) -> {
			FlxG.sound.music?.stop();
			var hxFile:String = Paths.getPath('scripts/states/$name.hx');
			if (FileSystem.exists(hxFile)) FlxG.switchState(() -> new HscriptState(hxFile));
			else {
				try {
					final rawClass:Class<Dynamic> = Type.resolveClass(name);
					if (rawClass == null) return;
					FlxG.switchState(() -> cast(Type.createInstance(rawClass, []), flixel.FlxState));
				} catch (e:AlterError) {
					Logs.error('$e: Unspecified result for switching state "$name", could not switch states');
					return;
				}
			}
		});
		set("openSubState", (name:String, args:Array<Dynamic>) -> {
			var hxFile:String = Paths.getPath('scripts/substates/$name.hx');
			if (FileSystem.exists(hxFile)) FlxG.state.openSubState(new HscriptSubstate(hxFile, args));
			else {
				try {
					final rawClass:Class<Dynamic> = Type.resolveClass(name);
					if (rawClass == null) return;
					FlxG.state.openSubState(cast(Type.createInstance(rawClass, args), FlxSubState));
				} catch (e:Dynamic) {
					Logs.error('$e: Unspecified result for opening substate "$name", could not be opened');
					return;
				}
			}
		});

		set('close', destroy);
		set('this', this);
		set('game', FlxG.state);
		set('controls', Controls);

		set('buildTarget', ScriptUtils.getTargetOS());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', ScriptUtils.Function_Stop);
		set('Function_Continue', ScriptUtils.Function_Continue);
		set('Function_StopHScript', ScriptUtils.Function_StopHScript);
		set('Function_StopAll', ScriptUtils.Function_StopAll);

		setParent(FlxG.state);
		if (PlayState.instance == FlxG.state) {
			var psInstance:PlayState = PlayState.instance;
			set('addBehindGF', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.gfGroup) - order, obj));
			set('addBehindDad', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.dadGroup) - order, obj));
			set('addBehindBF', (obj:FlxBasic, ?order:Int = 0) -> psInstance.insert(psInstance.members.indexOf(psInstance.boyfriendGroup) - order, obj));

			set('addBehindObject', (obj:FlxBasic, target:FlxBasic, ?order:Int = 0) -> return psInstance.insert(psInstance.members.indexOf(target), obj));
			set('addBehindCharacters', (obj:FlxBasic) -> return psInstance.insert(psInstance.members.indexOf(ScriptUtils.getLowestCharacterGroup()), obj));
		}
	}

	function getDefaultPreprocessors():Map<String, Dynamic> {
		var defines:Map<String, Dynamic> = macros.DefinesMacro.defines;
		defines.set("ALTER_ENGINE", true);
		defines.set("ALTER_VER", Main.engineVer);
		defines.set("ALTER_COMMIT", macros.GitCommitMacro.commitNumber);
		defines.set("ALTER_HASH", macros.GitCommitMacro.commitHash);
		return defines;
	}

	@:noUsing inline function getClassHSC(className:String):Class<Dynamic> {
		return Type.resolveClass('${className}_HSC');
	}

	override function call(funcToRun:String, ?args:Array<Dynamic>):AlterCall {
		if (funcToRun == null || interp == null) return null;

		if (!exists(funcToRun)) {
			AlterHscript.error('No function named: $funcToRun', this.interp.posInfos());
			return null;
		}

		try {
			var func:Dynamic = interp.variables.get(funcToRun); // function signature
			final ret:Dynamic = Reflect.callMethod(null, func, args ?? []);
			return {funName: funcToRun, signature: func, returnValue: ret};
		} catch (e:AlterError) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			AlterHscript.error(Printer.errorToString(e, false), pos);
		} catch (e:ValueException) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			AlterHscript.error(e.toString(), pos);
		}
		return null;
	}

	public override function destroy() {
		origin = null;
		super.destroy();
	}

	function set_varsToBring(values:Any):Any {
		if (varsToBring != null)
			for (key in Reflect.fields(varsToBring))
				if (exists(key.trim()))
					interp.variables.remove(key.trim());
		if (values != null) {
			for (key in Reflect.fields(values)) {
				key = key.trim();
				set(key, Reflect.field(values, key));
			}
		}
		return varsToBring = values;
	}
}
#else
class HScript {}
#end