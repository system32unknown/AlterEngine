package data;

@:keep
typedef SubtitleData = {
	/**
	 * The x position of the subtitle.
	 */
	@:default(640)
	public var ?x:Float;

	/**
	 * The y position of the subtitle.
	 */
	@:default(160)
	public var ?y:Float;

	/**
	 * The size of the subtitle text.
	 */
	@:default(36)
	public var ?subtitleSize:Int;

	/**
	 * The amount of time the subtitle shows before disappearing.
	 */
	@:default(1.0)
	public var ?duration:Float;

	/**
	 * The speed the subtitle types at.
	 */
	@:default(0.02)
	public var ?typeSpeed:Float;

	/**
	 * Whether the subtitle should just be at the center at the screen.
	 */
	@:default(true)
	public var ?centerScreen:Bool;

	/**
	 * If `centerScreen` is on, the axes in which the subtitle should be centered on.
	 */
	public var ?centerAxis:flixel.util.FlxAxes;

	/**
	 * The font of the subtitle text.
	 */
	public var ?font:String;
}
