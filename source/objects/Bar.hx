package objects;

import flixel.util.helpers.FlxBounds;
import flixel.math.FlxRect;

@:nullSafety
class Bar extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var valueFunction:Null<Void->Float> = null;
	public var percent(default, set):Float = 0;
	public var bounded(default, null):Float = 0;
	public var bounds:FlxBounds<Float> = new FlxBounds<Float>(0, 1);
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	/**
	 * Custom width set for the bars fill
	 * 
	 * default is bar frame width - 6
	 */
	public var barWidth(default, set):Int = 1;

	/**
	 * Custom height set for the bars fill
	 * 
	 * default is bar frame height - 6
	 */
	public var barHeight(default, set):Int = 1;

	/**
	 * additive offset for the bar fill position
	 */
	public var barOffset:FlxPoint = FlxPoint.get(3, 3);

	/**
	 * additive offset for the bg position
	 */
	public var bgOffset:FlxPoint = FlxPoint.get(0, 0);

	public function new(x:Float, y:Float, image:String = 'healthBar', ?valueFunction:Void->Float, boundX:Float = 0, boundY:Float = 1) {
		super(x, y);

		this.valueFunction = valueFunction;

		bg = new FlxSprite(Paths.image(image));
		bg.setPosition(bg.x + bgOffset.x, bg.y + bgOffset.y);

		@:bypassAccessor barWidth = Std.int(bg.width - 6);
		@:bypassAccessor barHeight = Std.int(bg.height - 6);

		leftBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height));
		rightBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height));
		rightBar.color = FlxColor.BLACK;

		antialiasing = Settings.data.antialiasing;

		add(leftBar);
		add(rightBar);
		add(bg);

		setBounds(boundX, boundY);
		regenerateClips();
	}

	public var enabled:Bool = true;
	override function update(elapsed:Float) {
		if (!enabled) {
			super.update(elapsed);
			return;
		}

		var value:Null<Float> = null;
		if (valueFunction != null) {
			bounded = FlxMath.bound(valueFunction(), bounds.min, bounds.max);
			value = FlxMath.remapToRange(bounded, bounds.min, bounds.max, 0, 100);
		}
		percent = value ?? 0;
		super.update(elapsed);
	}

	override public function destroy() {
		active = false;
		barOffset.put();
		bgOffset.put();
		super.destroy();
	}

	public function setBGOffset(x:Float, y:Float) {
		bgOffset.set(x, y);
		bg.x += bgOffset.x;
		bg.y += bgOffset.y;
	}

	public function setBounds(min:Float, max:Float):FlxBounds<Float> {
		return bounds.set(min, max);
	}

	public function setColors(?left:FlxColor, ?right:FlxColor) {
		if (left != null) leftBar.color = left;
		if (right != null) rightBar.color = right;
	}

	public function updateBar() {
		if (leftBar == null || rightBar == null) return;

		leftBar.setPosition(bg.x - bgOffset.x, bg.y - bgOffset.y);
		rightBar.setPosition(bg.x - bgOffset.x, bg.y - bgOffset.y);

		final leftSize:Float = FlxMath.lerp(0, barWidth, (leftToRight ? percent / 100 : 1 - percent / 100));

		leftBar.clipRect.set(barOffset.x, barOffset.y, leftSize, barHeight);
		rightBar.clipRect.set(barOffset.x + leftSize, barOffset.y, barWidth - leftSize, barHeight);

		barCenter = leftBar.x + leftSize + barOffset.x;
	}

	public function regenerateClips() {
		if (leftBar == null && rightBar == null) return;

		final width:Int = Std.int(bg.width);
		final height:Int = Std.int(bg.height);
		if (leftBar != null) {
			if (Std.int(leftBar.frameWidth) != Std.int(bg.frameWidth) || Std.int(leftBar.frameHeight) != Std.int(bg.frameHeight))
				leftBar.makeGraphic(Std.int(width), Std.int(height), FlxColor.WHITE);
			else leftBar.setGraphicSize(Std.int(width), Std.int(height));
			leftBar.updateHitbox();
			if (leftBar.clipRect == null) leftBar.clipRect = FlxRect.get(0, 0, width, height);
			else leftBar.clipRect.set(0, 0, width, height);
		}

		if (rightBar != null) {
			if (rightBar.frameWidth != Std.int(bg.frameWidth) || rightBar.frameHeight != Std.int(bg.frameHeight))
				rightBar.makeGraphic(Std.int(width), Std.int(height), FlxColor.WHITE);
			else rightBar.setGraphicSize(Std.int(width), Std.int(height));
			rightBar.updateHitbox();
			if (rightBar.clipRect == null) rightBar.clipRect = FlxRect.get(0, 0, width, height);
			else rightBar.clipRect.set(0, 0, width, height);
		}
		updateBar();
	}

	function set_percent(value:Float):Float {
		final doUpdate:Bool = (value != percent);
		percent = value;

		if (doUpdate) updateBar();
		return value;
	}

	function set_leftToRight(value:Bool):Bool {
		leftToRight = value;
		updateBar();
		return value;
	}

	function set_barWidth(value:Int):Int {
		barWidth = value;
		regenerateClips();
		return value;
	}

	function set_barHeight(value:Int):Int {
		barHeight = value;
		regenerateClips();
		return value;
	}

	override function set_x(Value:Float):Float { // for dynamic center point update
		final prevX:Float = x;
		super.set_x(Value);
		barCenter += Value - prevX;
		return Value;
	}

	override function set_antialiasing(Antialiasing:Bool):Bool {
		for (member in members)
			member.antialiasing = Antialiasing;
		return antialiasing = Antialiasing;
	}
}