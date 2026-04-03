package effects;

class AfterImage extends FlxTypedGroup<FlxSprite> {
	public var target:FlxSprite;

	public var delay:Float; // time between spawns
	public var lifetime:Float; // how long each afterimage lasts
	public var startAlpha:Float;
	public var color:Int;

	public var velocity:FlxPoint = FlxPoint.get();

	var _timer:Float = 0;

	public function new(target:FlxSprite, delay:Float = 0.03, lifetime:Float = 0.3, startAlpha:Float = 0.6, color:Int = 0xFFFFFFFF) {
		super();

		this.target = target;
		this.delay = delay;
		this.lifetime = lifetime;
		this.startAlpha = startAlpha;
		this.color = color;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (target == null || !target.exists) return;

		_timer += elapsed;

		if (_timer >= delay) {
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

	function spawnAfterimage() {
		var spr:FlxSprite = recycle(FlxSprite);

		spr.revive();

		// copy position
		spr.setPosition(target.x, target.y);

		// copy graphic/frame
		spr.loadGraphicFromSprite(target);

		// copy transforms
		spr.angle = target.angle;
		spr.scale.copyFrom(target.scale);
		spr.offset.copyFrom(target.offset);
		spr.flipX = target.flipX;
		spr.flipY = target.flipY;

		// visual style
		spr.alpha = startAlpha;
		spr.color = color;

		// velocity
		spr.velocity.copyFrom(velocity);
	}
}
