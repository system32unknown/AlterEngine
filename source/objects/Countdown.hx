package objects;

import flixel.tweens.misc.VarTween;

typedef CountdownParams = {
	/**
	 * Whether the countdown should be visible or not.
	 */
	var enabled:Bool;

	/**
	 * Whether each tick from the countdown should play a sound.
	 */
	var playSound:Bool;

	/**
	 * The duration of the countdown's animation.
	 */
	var duration:Float;

	/**
	 * The speed of the countdown's animation. The lower it is, the slower it goes and vice-versa.
	 */
	var speed:Float;
}

class Countdown extends FlxSpriteGroup {
	public var enabled:Bool;
	public var playSound:Bool;
	public var duration:Float;
	public var speed:Float;

	public var introSoundsSuffix:String = '';
	public var introSoundNames:Array<String> = [];

	public function new(params:CountdownParams) {
		super();

		this.enabled = params.enabled;
		this.playSound = params.playSound;
		this.duration = params.duration;
		this.speed = params.speed;
	}

	function getCountdownSpriteNames(?givenUI:Null<String>):Array<String> {
		final ui:String = (givenUI ?? PlayState.stageUI);
		final key:String = ui.toLowerCase();

		inline function build(prefix:String, suffix:String):Array<String> {
			return ['${prefix}ready${suffix}', '${prefix}set${suffix}', '${prefix}go${suffix}'];
		}

		return switch (key) {
			case "pixel": build("pixelUI/", "-pixel");
			case "normal": build("countdown/", "");
			default: build('${PlayState.uiPrefix}UI/', PlayState.uiPostfix);
		};
	}

	public function makeTween(sprite:FlxSprite, values:Dynamic, easing:EaseFunction):VarTween {
		return FlxTween.tween(sprite, values, (this.duration / this.speed), {
			ease: easing,
			onComplete: function(twn:FlxTween) {
				sprite.destroy();
				remove(sprite, true);
			}
		});
	}

	public function cache():Void {}
}
