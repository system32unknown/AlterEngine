package substates;

class OutdatedSubState extends MusicBeatSubstate {
	public static var updateVersion:Array<String> = Util.checkForUpdates();
	public static var leftState:Bool = false;

	var bg:FlxSprite;
	var warnText:FlxText;

	override function create() {
		super.create();

		bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.0;
		add(bg);

		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			'Sup bro, looks like you\'re running an outdated version of Alter Engine (${Main.engineVer}),\n
			-----------------------------------------------\n
			What\'s new:\n
			${updateVersion[1]}\n
			-----------------------------------------------\n
			Press ENTER to update to the latest version ${updateVersion[0]}\n
			Press ESCAPE to proceed anyway.\n
			You can disable this warning by unchecking the
			"Check for Updates" setting in the Options Menu\n
			-----------------------------------------------\n
			Thank you for using the Engine!', 32);
		txt.setFormat(Paths.font("vcr.ttf"), txt.size, FlxColor.WHITE, CENTER);
		txt.gameCenter(Y);
		txt.alpha = 0.0;
		add(txt);

		FlxTween.tween(bg, {alpha: .8}, .6, {ease: FlxEase.sineIn});
		FlxTween.tween(warnText, {alpha: 1.}, .6, {ease: FlxEase.sineIn});
	}

	override function update(elapsed:Float) {
		if (leftState) {
			super.update(elapsed);
			return;
		}

		if (Controls.justPressed('accept')) {
			leftState = true;
			Util.browserLoad("https://github.com/system32unknown/AlterEngine/releases");
		} else if (Controls.justPressed('back')) leftState = true;

		if (leftState) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxTween.tween(bg, {alpha: 0.0}, .9, {ease: FlxEase.sineOut});
			FlxTween.tween(warnText, {alpha: 0}, 1, {
				ease: FlxEase.sineOut,
				onComplete: (twn:FlxTween) -> {
					FlxG.state.persistentUpdate = true;
					close();
				}
			});
		}
		super.update(elapsed);
	}
}