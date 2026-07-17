package states;

typedef TitleData = {
	var titlex:Float;
	var titley:Float;
	var titlesize:Float;
	var titlestarty:Float;
	var startx:Float;
	var starty:Float;
	var gfx:Float;
	var gfy:Float;
	var backgroundSprite:String;
	var bpm:Float;

	@:optional var animation:String;
	@:optional var dance_left:Array<Int>;
	@:optional var dance_right:Array<Int>;
	@:optional var idle:Bool;
}

class TitleState extends MusicBeatState {
	override function create():Void {
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();
		FlxG.mouse.visible = false;
		persistentUpdate = true;

		loadJsonData();
		prepareIntro();
		Conductor.bpm = musicBPM;

		curWacky = getIntroTextShit();
		if (seenIntro) {
			skipIntro();
			return;
		}

		if (FlxG.sound.music == null) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, .7);
		}
	}

	var logo:FlxSprite;
	var foundXml:Bool = false;
	var gf:FlxSprite;
	var titleText:FlxSprite;

	var introGroup:FlxSpriteGroup;
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];
	var curWacky:Array<String> = [];
	public static var seenIntro:Bool = false;
	var textGroup:FlxTypedGroup<FlxText>;
	function prepareIntro() {
		add(introGroup = new FlxSpriteGroup());
		introGroup.visible = false;

		logo = new FlxSprite(logoPosition.x, logoPosition.y);
		logo.antialiasing = Settings.data.antialiasing;
		if (!FileSystem.exists(Paths.modsXml('logobumpin'))) {
			logo.loadGraphic(Paths.image('logobumpin'));
			logo.setGraphicSize(Std.int(logo.width * titleSize));
		} else {
			foundXml = true;
			logo.frames = Paths.sparrowAtlas('logobumpin');
			logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logo.animation.play('bump');
		}
		logo.updateHitbox();
		logo.angle = -4;

		gf = new FlxSprite(gfPosition.x, gfPosition.y);
		gf.frames = Paths.sparrowAtlas(characterImage);
		gf.antialiasing = Settings.data.antialiasing;

		if (!useIdle) {
			gf.animation.addByIndices('left', animationName, danceLeftFrames, '', 24, false);
			gf.animation.addByIndices('right', animationName, danceRightFrames, '', 24, false);
			gf.animation.play('right');
		} else {
			gf.animation.addByPrefix('idle', animationName, 24, false);
			gf.animation.play('idle');
		}
		
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.sparrowAtlas('titleEnter');

		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if (newTitle = animFrames.length > 0) {
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', Settings.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
			FlxTween.num(0, 1, 2, {type: PINGPONG, ease: FlxEase.quadInOut}, num -> titleTextTimer = num);
		} else {
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();

		add(textGroup = new FlxTypedGroup<FlxText>());
		introGroup.add(gf);
		introGroup.add(logo); // FNF Logo
		introGroup.add(titleText); //"Press Enter to Begin" text
	}

	// JSON data
	var characterImage:String = 'gfDanceTitle';
	var animationName:String = 'gfDance';

	var titleStartY:Float = 50;
	var titleSize:Float = 1.1;
	var gfPosition:FlxPoint = FlxPoint.get(512, 40);
	var logoPosition:FlxPoint = FlxPoint.get(0, 1500);
	var enterPosition:FlxPoint = FlxPoint.get(125, 576);

	var useIdle:Bool = false;
	public static var musicBPM:Float = 148;
	var danceLeftFrames:Array<Int> = [for (i in 15...30) i];
	var danceRightFrames:Array<Int> = [30].concat([for (i in 0...15) i]);

	function loadJsonData() {
		final titlefile:String = 'data/titleData.json';
		if (!Paths.fileExists(titlefile)) {
			Logs.warn('No Title JSON detected, using default values.');
			return;
		}

		var titleRaw:String = Paths.getTextFromFile(titlefile);
		if (titleRaw == null || titleRaw.length == 0) return;

		try {
			var titleJSON:TitleData = tjson.TJSON.parse(titleRaw);

			gfPosition.set(titleJSON.gfx, titleJSON.gfy);
			logoPosition.set(titleJSON.titlex, titleJSON.titley);
			enterPosition.set(titleJSON.startx, titleJSON.starty);

			titleSize = titleJSON.titlesize;
			titleStartY = titleJSON.titlestarty;
			musicBPM = titleJSON.bpm;

			if (titleJSON?.animation.length > 0) animationName = titleJSON.animation;
			if (titleJSON?.dance_left.length > 0) danceLeftFrames = titleJSON.dance_left;
			if (titleJSON?.dance_right.length > 0) danceRightFrames = titleJSON.dance_right;
			useIdle = (titleJSON.idle == true);

			if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.trim().length > 0) {
				var bg:FlxSprite = new FlxSprite(Paths.image(titleJSON.backgroundSprite));
				bg.antialiasing = Settings.data.antialiasing;
				bg.active = false;
				add(bg);
			}
		} catch (e:haxe.Exception) Logs.warn('Title JSON might broken, ignoring issue...\n${e.details()}');
	}

	function getIntroTextShit():Array<String> {
		var firstArray:Array<String> = #if MODS_ALLOWED Mods.mergeAllTextsNamed('data/introText.txt') #else File.getContent(Paths.txt('introText')).split('\n') #end;
		return FlxG.random.getObject([for (i in firstArray) i.split('--')]);
	}

	var newTitle:Bool = false;
	var titleTextTimer:Float = 0;
	var titleTimer:Float = 0;
	function updateTitleText(elapsed:Float) {
		if (!newTitle || !seenIntro || skipped) return;

		titleTimer += elapsed;
		logo.angle = Math.sin(titleTimer * 2.) * 5; // stable across FPS

		titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], titleTextTimer);
		titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], titleTextTimer);
	}

	var skipped:Bool = false;
	var transitionTmr:FlxTimer;
	var transitioning:Bool = false;
	override function update(elapsed:Float) {
		updateTitleText(elapsed);
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		if (Controls.justPressed('accept') || FlxG.mouse.justPressed) {
			if (!seenIntro) {
				skipIntro();
				return;
			}

			if (skipped) {
				moveToMainMenu();
				return;
			}

			FlxTween.tween(logo, {y: -700}, 1, {ease: FlxEase.backIn});
			titleText.animation.play('press');
			titleText.color = FlxColor.WHITE;
			titleText.alpha = 1;

			FlxG.camera.flash(Settings.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF);
			FlxG.sound.play(Paths.sound('confirmMenu'), .7);

			skipped = true;
			transitionTmr = FlxTimer.wait(1.5, () -> moveToMainMenu());
		}

		super.update(elapsed);
	}

	function moveToMainMenu():Void {
		if (transitionTmr != null) {
			transitionTmr.cancel();
			transitionTmr = null;
		}
		FlxG.switchState(() -> new MainMenuState());
	}

	function createText(textArray:Array<String>, offset:Float = 0):Void {
		for (i in 0...textArray.length) addMoreText(textArray[i], offset, i);
	}
	function addMoreText(text:String, offset:Float = 0, i:Int = -1):Void {
		if (textGroup == null) return;

		final txt:FlxText = new FlxText(0, ((i == -1 ? textGroup.length : i) * 60) + 200 + offset, FlxG.width, text, 48);
		txt.setFormat(Paths.font("babyshark.ttf"), 48, FlxColor.WHITE, CENTER);
		txt.gameCenter(X);
		textGroup.add(txt);
	}
	inline function deleteText():Void {
		while (textGroup.members.length > 0) textGroup.remove(textGroup.members[0], true);
	}

	var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen
	override function beatHit() {
		super.beatHit();

		if (foundXml) logo.animation.play('bump', true);

		if (!useIdle) {
			gf.animation.play(curBeat % 2 == 0 ? 'left' : 'right');
		} else if (curBeat % 2 == 0) gf.animation.play('idle');

		if (seenIntro) return;

		sickBeats++;
		switch (sickBeats) {
			case 1: createText(['Vs Dave and Bambi by:']);
			case 2:
				addMoreText('MoldyGH, MTM101, Stats45');
				addMoreText('Rapparep lol, TheBuilderXD, Edival');
				addMoreText('T5mpler, Erizur, Billy Bobbo');
			case 3:
				deleteText();
				createText(['Baby Shark\'s Big Show by:']);
			case 4:
				addMoreText('Pinkfong');
				addMoreText('Nickelodeon');
				addMoreText('SmartStudy');
			case 5:
				deleteText();
				createText(['Psych Engine by:']);
			case 6:
				addMoreText('Shadow Mario');
				addMoreText('Riveren');
				addMoreText('And Psych Engine Contributors!');
			case 7:
				deleteText();
				createText(['Altertoriel']);
			case 8:
				addMoreText('Presents!');
			case 9:
				deleteText();
				createText([curWacky[0]]);
			case 10: addMoreText(curWacky[1]);
			case 11: deleteText();
			case 12: addMoreText('Baby');
			case 13: addMoreText('Shark\'s');
			case 14: addMoreText('Big Funkin!');
			case 15: skipIntro();
		}
	}

	function skipIntro() {
		FlxTween.tween(logo, {y: titleStartY}, 1.4, {ease: FlxEase.expoInOut});
		deleteText();
		introGroup.visible = true;
		FlxG.camera.flash(FlxColor.WHITE, 2);
		seenIntro = true;
	}
}