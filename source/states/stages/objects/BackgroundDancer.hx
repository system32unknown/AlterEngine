package states.stages.objects;

class BackgroundDancer extends FlxSprite {
	public function new(x:Float, y:Float) {
		super(x, y);

		frames = Paths.sparrowAtlas("limo/limoDancer");
		animation.addByIndices('danceLeft', 'bg dancer sketch', [for (i in 0...14) i], "", 24, false);
		animation.addByIndices('danceRight', 'bg dancer sketch', [for (i in 15...30) i], "", 24, false);
		animation.play('danceLeft');
		antialiasing = Settings.data.antialiasing;
	}

	var danceDir:Bool = false;
	public function dance():Void {
		danceDir = !danceDir;

		if (danceDir) animation.play('danceRight', true);
		else animation.play('danceLeft', true);
	}
}