package effects;

class AfterImage extends #if (flixel < version("5.7.0")) FlxTypedGroup<FlxSprite> #else flixel.group.FlxSpriteContainer #end {
	public var target:FlxSprite;

	public var delay:Float;
	public var enabled:Bool = true;

	public var lifetime:Float;
	public var startAlpha:Float;

	public var _vel:FlxPoint = FlxPoint.get();
	public var _accel:FlxPoint = FlxPoint.get();
	public var _drag:FlxPoint = FlxPoint.get();

	var _timer:Float = 0;

	/**
	 * Creates a new AfterImage.
	 * 
	 * @param target The sprite to follow
	 * @param delay Time between afterimage spawns
	 * @param lifetime Duration each afterimage exists
	 * @param startAlpha Initial transparency of afterimages
	 */
	public function new(target:FlxSprite, delay:Float = .03, lifetime:Float = .3, startAlpha:Float = .6) {
		super();

		this.target = target;
		this.delay = delay;
		this.lifetime = lifetime;
		this.startAlpha = startAlpha;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (target == null || !target.exists) return;

		_timer += elapsed;

		if (_timer >= delay && enabled) {
			_timer = 0;
			spawnAfterimage();
		}

		// update fade
		for (sprite in members) {
			if (sprite != null && sprite.exists) {
				sprite.alpha -= elapsed / lifetime;
				if (sprite.alpha <= 0) sprite.kill();
			}
		}
	}

	/**
	 * Creates and initializes a new afterimage sprite.
	 * Copies visual properties from the target and assigns velocity.
	 */
	public function spawnAfterimage():Void {
		var spr:FlxSprite = recycle(FlxSprite);
		spr.revive();

		// copy position
		spr.setPosition(target.x, target.y);

		// copy graphic/frame
		spr.loadGraphicFromSprite(target);
		spr.animation?.stop();

		// copy transforms
		spr.angle = target.angle;
		spr.origin.copyFrom(target.origin);
		spr.scale.copyFrom(target.scale);
		spr.offset.copyFrom(target.offset);
		spr.flipX = target.flipX;
		spr.flipY = target.flipY;

		// visual style
		spr.alpha = startAlpha;
		spr.color = color;

		// velocity
		spr.velocity.copyFrom(_vel);
		spr.acceleration.copyFrom(_accel);
		spr.drag.copyFrom(_drag);
	}
}
