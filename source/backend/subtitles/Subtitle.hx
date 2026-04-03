package backend.subtitles;

import data.SubtitleData;

/**
 * A UI element used to display text in-case a player is speaking.
 */
class Subtitle extends flixel.addons.text.FlxTypeText {
	/**
	 * The data used to initalize this subtitle.
	 */
	var data:SubtitleData;

	/**
	 * The manager this Subtitle belongs to.
	 */
	public var manager:SubtitleManager;

	/**
	 * Initalize a new Subtitle.
	 * 
	 * @param text
	 * @param data The data this subtitle belongs to.
	 * @param manager The manager this subtitle is contained to.
	 */
	public function new(text:String, data:SubtitleData, manager:SubtitleManager) {
		this.data = data;
		this.manager = manager;

		super(data.x, data.y, FlxG.width, text, data.subtitleSize);		
		setup();
	}

	/**
	 * Constructs this subtitle based on the given data.
	 */
	public function setup():Void {
		setFormat(data.font, data.subtitleSize, FlxColor.WHITE, CENTER);
		setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		antialiasing = Settings.data.antialiasing;
		if (data.centerScreen) gameCenter(data.centerAxis);
	}

	/**
	 * Start the subtitle typing process of this subtitle.
	 */
	public function startSubtitle():Void {
		start(data.typeSpeed, false, false, [], () -> beginSubtitleEnd());
	}

	public function beginSubtitleEnd():Void {
		FlxTimer.wait(data.duration, () -> FlxTween.tween(this, {alpha: 0}, .5, {onComplete: (tween:FlxTween) -> manager.onSubtitleComplete(this)}));
	}
}