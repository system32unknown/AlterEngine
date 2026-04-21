package objects;

import flixel.graphics.FlxGraphic;

typedef BopInfo = {
	var curBeat:Int;
	var ?playbackRate:Float;
	var ?gfSpeed:Int;
	var ?percent:Float;
}

class HealthIcon extends FlxSprite {
	static final prefix:String = 'icons/';
	static final defaultIcon:String = 'icon-face';
	static final ICON_TARGET:Int = 150;

	public var iconZoom:Float = 1;
	public var sprTracker:FlxSprite;
	public var isPixelIcon(get, null):Bool;
	public var animated(default, null):Bool;

	public var iconType:String = "vanilla";
	public var iSize(default, null):Int = 1;
	public var autoOffset:Bool = false;

	var isPlayer:Bool = false;
	var char:String = '';
	var state:Int = 0;

	var _scale:FlxPoint;
	final animatedIconStates:Array<String> = ['normal', 'lose', 'win'];

	var iconOffset:FlxPoint = FlxPoint.get();

	public static function returnGraphic(char:String, defaultIfMissing:Bool = false, ?allowGPU:Bool = true):FlxGraphic {
		var path:String = prefix + char;
		if (!Paths.fileExists('images/$path.png', IMAGE)) path = prefix + 'icon-$char'; // Older versions of psych engine's support
		if (!Paths.fileExists('images/$path.png', IMAGE)) { // Prevents crash from missing icon
			if (!defaultIfMissing) return null;
			path = prefix + defaultIcon;
			if (!Paths.fileExists('images/$path.png', IMAGE)) return null; // still missing
		}

		return Paths.image(path, allowGPU);
	}

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true) {
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	@:noCompletion override function initVars():Void {
		super.initVars();
		_scale = FlxPoint.get();
	}

	override function destroy():Void {
		super.destroy();
		if (_scale != null) _scale.put();
	}

	override function draw():Void {
		if (iconZoom == 1) return super.draw();
		_scale.copyFrom(scale);
		scale.scale(iconZoom);
		super.draw();
		_scale.copyTo(scale);
	}

	public function getCharacter():String return char;

	@:noCompletion inline function get_isPixelIcon():Bool
		return char.endsWith("-pixel");

	public function changeIcon(char:String, defaultIfMissing:Bool = true, ?allowGPU:Bool = true):Bool {
		if (this.char == char) return false;

		var name:String = 'icons/$char';
		animated = Paths.fileExists('images/$name.xml');

		var graph:FlxGraphic = returnGraphic(char, defaultIfMissing, allowGPU);
		if (graph == null) return false;

		this.char = char;
		state = 0;

		// Determine size (static icons are usually N frames stacked horizontally)
		iSize = Math.round(graph.width / graph.height);

		if (!animated) {
			loadGraphic(graph, true, Math.floor(graph.width / iSize), Math.floor(graph.height));
			animation.add(char, [for (i in 0...frames.frames.length) i], 0, false, isPlayer);
			iconOffset.set((width - ICON_TARGET) / iSize, (height - ICON_TARGET) / iSize);
			animation.play(char);
		} else {
			frames = Paths.sparrowAtlas(name);

			for (stateName in animatedIconStates) {
				if (getIconAnims(name).contains(stateName)) {
					animation.addByPrefix(stateName, stateName, 24, true, isPlayer, false);
				}
			}

			if (animation.exists(animatedIconStates[0])) animation.play(animatedIconStates[0], true);
			else if (animation.getNameList().length > 0) animation.play(animation.getNameList()[0], true);
		}

		// Zoom depends on pixel suffix (keeps your original intent)
		iconZoom = isPixelIcon ? (ICON_TARGET / graph.height) : 1;

		updateHitbox();
		antialiasing = (iconZoom < 2.5) && Settings.data.antialiasing;
		return true;
	}

	override function updateHitbox():Void {
		var t:String = iconType.toLowerCase();
		if (t == 'center') {
			centerOrigin();
		} else if (t == 'psych') {
			super.updateHitbox();
			width *= iconZoom;
			height *= iconZoom;
			offset.set(-.5 * (frameWidth * iconZoom - frameWidth), -.5 * (frameHeight * iconZoom - frameHeight));
		} else super.updateHitbox();

		if (autoOffset) offset.copyFrom(iconOffset);
	}

	public function setStateIndex(newState:Int):Void {
		if (iSize <= 0) iSize = 1;
		if (newState >= iSize) newState = 0;

		if (state == newState || animation.curAnim == null) return;

		state = newState;
		animation.curAnim.curFrame = newState;
	}

	public function setState(newState:Int):Void {
		if (!animated) {
			setStateIndex(newState);
			return;
		}

		if (newState < 0 || newState >= animatedIconStates.length) return;

		var name:String = animatedIconStates[newState];
		if (animation.exists(name)) animation.play(name, true);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		// keep existing behavior
		if (Std.isOfType(FlxG.state, PlayState) && (Settings.data.iconBopType == 'Dave' || Settings.data.iconBopType == 'GoldenApple'))
			offset.set(Std.int(FlxMath.bound(width - ICON_TARGET, 0)), Std.int(FlxMath.bound(height - ICON_TARGET, 0)));

		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public var curBopType(default, set):String = "None";
	var iconSizeResetTime:Float = 0;

	public dynamic function bopUpdate(e:Float, rate:Float):Void {
		switch (curBopType.toLowerCase()) {
			case "old": setGraphicSize(Std.int(FlxMath.lerp(ICON_TARGET, width, .5)));
			case "psych":
				var mult:Float = FlxMath.lerp(1, scale.x, Math.exp(-e * 9 * rate));
				scale.set(mult, mult);
			case "dave":
				iconSizeResetTime = Math.max(0, iconSizeResetTime - e / rate);
				var iconLerp:Float = FlxEase.quartIn(iconSizeResetTime / .8);
				setGraphicSize(Std.int(FlxMath.lerp(frameWidth, width, iconLerp)), Std.int(FlxMath.lerp(frameHeight, height, iconLerp)));
		}
		updateHitbox();
	}

	/**
	 * Internal function to animate the Icon.
	 * @param bopInfo {curBeat, playbackRate, gfSpeed, healthBarPercent} curBeat is mandatory, the rest are limited to PlayState.
	 * @param iconAnim The name of the Animation, set to "Client"
	 * @param type (0 = BF, 1 = DAD)
	 * Values are necessary for proper calculations.
	 */
	public dynamic function bop(bopInfo:BopInfo, iconAnim:String = "Settings", type:Int = 0):Void {
		var requested:String = iconAnim.toLowerCase();
		if (requested == "settings" || requested == "clientprefs" || requested == "client") iconAnim = Settings.data.iconBopType;
		if (iconAnim == "None") return;

		if (curBopType != iconAnim) curBopType = iconAnim;

		final info:BopInfo = checkInfo(bopInfo);
		if (info.curBeat % info.gfSpeed != 0) return;

		switch (iconAnim.toLowerCase()) {
			case "old": setGraphicSize(Std.int(width + 30));
			case "psych": scale.set(1.2, 1.2);
			case "dave":
				var funny:Float = FlxMath.bound(info.percent, .1, 1.9);
				if (type == 0) setGraphicSize(Std.int(width + (50 * (funny + .1))), Std.int(height - (25 * funny)));
				else {
					var inv:Float = (2 - funny) + .1;
					setGraphicSize(Std.int(width + (50 * inv)), Std.int(height - (25 * inv)));
				}
				iconSizeResetTime = .8;
			case "goldenapple":
				var everyOther:Bool = (info.curBeat % (info.gfSpeed * 2)) == 0;
				var iconAngle:Float = everyOther ? -15 : 15;

				if (type == 0) {
					scale.set(1.1, everyOther ? .8 : 1.3);
					FlxTween.angle(this, iconAngle, 0, Conductor.crochet / 1300 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
				} else {
					scale.set(1.1, everyOther ? 1.3 : .8);
					FlxTween.angle(this, -iconAngle, 0, Conductor.crochet / 1300 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
				}

				FlxTween.tween(this, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
		}
		updateHitbox();
	}

	function set_curBopType(newType:String):String { // Resets values
		curBopType = newType;
		angle = 0;
		scale.set(1, 1);
		setGraphicSize(ICON_TARGET, ICON_TARGET);
		updateHitbox();
		return curBopType;
	}

	inline function checkInfo(oldInfo:BopInfo):BopInfo {
		return {
			curBeat: oldInfo.curBeat,
			playbackRate: oldInfo.playbackRate ?? 1,
			gfSpeed: oldInfo.gfSpeed ?? 1,
			percent: oldInfo.percent ?? 50
		};
	}

	function getIconAnims(file:String):Array<String> {
		final regNum:EReg = ~/[\d-]/;
		return Util.removeDupString([for (icon in new haxe.xml.Access(Xml.parse(Paths.getTextFromFile('images/$file.xml')).firstElement()).nodes.SubTexture) regNum.split(icon.att.name)[0]]);
	}
}