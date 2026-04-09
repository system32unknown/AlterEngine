package objects;

enum PopupType {
	NONE;
	RATING;
	NUMBER;
	CUSTOM(popX:Float, popY:Float, size:Float);
}

class Popup extends FlxSprite {
	public static var baseAcc:FlxPoint = FlxPoint.get();
	public static var baseVel:FlxPoint = FlxPoint.get();
	public static var noVelocity:Bool = false;

	public var type:PopupType = NONE;
	public var popUpTime:Float = 0;

	final placement:Float = FlxG.width * .35;

	var i:PlayState;
	var baseRate:Float = 0.0;
	var comboOffset:Array<Array<Int>> = [];

	public function new():Void {
		super();

		i = PlayState.instance;
		baseRate = i.playbackRate * i.playbackRate;
		comboOffset = Settings.data.comboOffset;
	}

	/**
	 * Loads/assigns a popup texture and caches its frames by `target`.
	 * Always returns `this` for chaining.
	 */
	public function reloadTexture(target:String):Popup {
		popUpTime = Conductor.songPosition;

		var cached:flixel.graphics.frames.FlxFramesCollection = Paths.popUpFramesMap.get(target);
		if (cached != null) {
			frames = cached;
			return this;
		}

		loadGraphic(Paths.image(target));
		Paths.popUpFramesMap.set(target, frames);
		return this;
	}

	public function setupPopupData(popUptype:PopupType = NONE, img:String, ?index:Int, ?comboDigit:Int):Void {
		type = popUptype;
		reloadTexture(img);

		var isPixel:Bool = PlayState.isPixelStage;
		var zoom:Float = PlayState.daPixelZoom;

		switch (popUptype) {
			case NUMBER:
				x = placement + (43 * index) - 50 + comboOffset[1][0] + (0 - (comboDigit + Std.int((comboDigit - 1) / 3) / 2 - 3)) * 22;
				gameCenter(Y).y += 20 - comboOffset[1][1];
				setGraphicSize(Std.int(width * (isPixel ? zoom : .5)));
			case RATING:
				x = placement - 40 + comboOffset[0][0];
				gameCenter(Y).y -= 60 + comboOffset[0][1];
				setGraphicSize(Std.int(width * (isPixel ? (.85 * zoom) : .7)));
			case CUSTOM(popX, popY, size):
				setPosition(popX, popY);
				setGraphicSize(Std.int(width * size));
			case NONE:
		}

		updateHitbox();

		if (!noVelocity) {
			var rate:Float = i.playbackRate;
			if (popUptype == RATING) {
				velocity.set(-FlxG.random.int(0, 10) * rate + baseVel.x, -FlxG.random.int(140, 175) * rate + baseVel.y);
				acceleration.set(baseAcc.x * baseRate, 550 * baseRate + baseAcc.y);
			} else {
				velocity.set(FlxG.random.float(-5, 5) * rate + baseVel.x, -FlxG.random.int(130, 150) * rate + baseVel.y);
				acceleration.set(baseAcc.x * baseRate, FlxG.random.int(250, 300) * baseRate + baseAcc.y);
			}
		}

		visible = !Settings.data.hideHud;
		antialiasing = i.popupAntialias;
	}

	public dynamic function doTween(speed:Float = .001):Void {
		FlxTween.cancelTweensOf(this);
		FlxTween.tween(this, {alpha: 0}, .2 / i.playbackRate, {onComplete: (tween:FlxTween) -> kill(), startDelay: Conductor.crochet * speed / i.playbackRate});
	}

	override public function kill():Void {
		type = NONE;
		exists = visible = false;
	}

	override public function revive():Void {
		exists = visible = true;
		initVars();
		acceleration.set();
		velocity.set();
		setPosition();
		alpha = 1;
	}
}