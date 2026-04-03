package backend.subtitles;

/**
 * A container that stores a list of subtitles for it's specific entry.
 */
class SubtitleManager extends FlxSpriteGroup {
	/**
	 * A group used to contain all of the subtitles that appear on this sprite.
	 */
	var subtitlesGroup:FlxTypedSpriteGroup<Subtitle> = new FlxTypedSpriteGroup<Subtitle>();

	public function new():Void {
		super();
		add(subtitlesGroup);
	}

	/**
	 * Adds a subtitle to the manager.
	 * @param text The subtitle to adds text.
	 * @param data The subtitle to add.
	 */
	public function addSubtitle(text:String, data:data.SubtitleData):Void {
		var subtitle:Subtitle = new Subtitle(text, data, this);
		subtitlesGroup.add(subtitle);
		subtitle.startSubtitle();
	}

	/**
	 * Called when a subtitle has finished.
	 * @param subtitle The subtitle that was completed.
	 */
	public function onSubtitleComplete(subtitle:Subtitle):Void {
		subtitlesGroup.remove(subtitle);
	}

	/**
	 * Destroys this data object.
	 */
	override function destroy():Void {
		for (subtitle in subtitlesGroup) {
			subtitlesGroup.remove(subtitle);

			subtitle.destroy();
			subtitle = null;
		}
		subtitlesGroup.clear();

		super.destroy();
	}
}
