package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import options.OptionsState;
import substates.OutdatedSubState;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState {
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;
	var allowMouse:Bool = true;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits'
	];

	var leftOption:String = #if AWARDS_ALLOWED 'awards' #else null #end;
	var rightOption:String = 'options';

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	static var showOutdatedWarning:Bool = true;
	override function create() {
		super.create();
		#if MODS_ALLOWED Mods.pushGlobalMods(); #end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED DiscordClient.changePresence(); #end
		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (.05 * (optionShit.length - 4)), .1);
		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.antialiasing = Settings.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.gameCenter();
		bg.color = 0xFFFDE871;
		add(bg);
		
		add(camFollow = new FlxObject(FlxG.width * .5, 0, 1, 1));

		magenta = new FlxSprite(bg.graphic);
		magenta.antialiasing = Settings.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.gameCenter();
		magenta.visible = magenta.active = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		add(menuItems = new FlxTypedGroup<FlxSprite>());

		var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
		for (i => option in optionShit) {
			var item:FlxSprite = createItem(option, 0, (i * 140) + offset);
			menuItems.add(item);

			item.scrollFactor.set(0, optionShit.length < 6 ? 0 : (optionShit.length - 4) * .135);
			item.updateHitbox();
			item.gameCenter(X);
		}

		if (leftOption != null) {
			leftItem = createItem(leftOption, 60, 490, true);
			leftItem.updateHitbox();
			menuItems.add(leftItem);
		}
		if (rightOption != null) {
			rightItem = createItem(rightOption, FlxG.width - 60, 490, true);
			rightItem.updateHitbox();
			rightItem.x -= rightItem.width;
			menuItems.add(rightItem);
		}

		var version:FlxText = new FlxText(0, 0, 0, 'AE v${Main.engineVer} (${Main.engineVer.COMMIT_HASH})', 16);
		version.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, RIGHT);
		version.setBorderStyle(OUTLINE, FlxColor.BLACK);
		version.scrollFactor.set();
		version.setPosition(FlxG.width - version.width, FlxG.height - version.height);
		add(version);
		changeItem();

		#if (AWARDS_ALLOWED && MODS_ALLOWED) Awards.reloadList(); #end

		#if CHECK_FOR_UPDATES
		if (showOutdatedWarning && Settings.data.checkForUpdates && OutdatedSubState.updateVersion[0] != Main.engineVer) {
			persistentUpdate = showOutdatedWarning = false;
			openSubState(new OutdatedSubState());
		}
		#end
		FlxG.camera.follow(camFollow, null, .15);
	}

	function createItem(name:String, x:Float, y:Float, looping:Bool = false):FlxSprite {
		final item:FlxSprite = new FlxSprite(x, y);
		item.antialiasing = Settings.data.antialiasing;
		item.scrollFactor.set();
		item.frames = Paths.sparrowAtlas('mainmenu/menu_$name');
		item.animation.addByPrefix('idle', '$name idle', 24, true);
		item.animation.addByPrefix('selected', '$name selected', 24, !looping);
		item.animation.play('idle');
		return item;
	}

	var selectedSomethin:Bool = false;
	var timeNotMoving:Float = 0;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < .8) {
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + .5 * elapsed, .8);
			if (FreeplayState.vocals != null) FreeplayState.vocals.volume += .5 * elapsed;
		}
		
		if (selectedSomethin) {
			super.update(elapsed);
			return;
		}

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) changeItem(downJustPressed ? 1 : -1);

		var allowMouse:Bool = allowMouse;
		if (allowMouse && ((FlxG.mouse.deltaViewX != 0 && FlxG.mouse.deltaViewY != 0) || FlxG.mouse.justPressed)) { //more accurate than FlxG.mouse.justMoved
			allowMouse = false;
			FlxG.mouse.visible = true;
			timeNotMoving = 0;

			var selectedItem:FlxSprite;
			switch (curColumn) {
				case CENTER: selectedItem = menuItems.members[curSelected];
				case LEFT: selectedItem = leftItem;
				case RIGHT: selectedItem = rightItem;
			}

			if (leftItem != null && FlxG.mouse.overlaps(leftItem)) {
				allowMouse = true;
				if (selectedItem != leftItem) {
					curColumn = LEFT;
					changeItem();
				}
			} else if (rightItem != null && FlxG.mouse.overlaps(rightItem)) {
				allowMouse = true;
				if (selectedItem != rightItem) {
					curColumn = RIGHT;
					changeItem();
				}
			} else {
				var dist:Float = -1;
				var distItem:Int = -1;
				for (i in 0...optionShit.length) {
					var memb:FlxSprite = menuItems.members[i];
					if (FlxG.mouse.overlaps(memb)) {
						var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.viewX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.viewY, 2));
						if (dist < 0 || distance < dist) {
							dist = distance;
							distItem = i;
							allowMouse = true;
						}
					}
				}

				if (distItem != -1 && selectedItem != menuItems.members[distItem]) {
					curColumn = CENTER;
					curSelected = distItem;
					changeItem();
				}
			}
		} else {
			timeNotMoving += elapsed;
			if (timeNotMoving > 2) FlxG.mouse.visible = false;
		}

		var leftJustpressed:Bool = Controls.justPressed('ui_left');
		var rightJustpressed:Bool = Controls.justPressed('ui_right');
		switch (curColumn) {
			case CENTER:
				if (leftJustpressed && leftOption != null) {
					curColumn = LEFT;
					changeItem();
				} else if (rightJustpressed && rightOption != null) {
					curColumn = RIGHT;
					changeItem();
				}
			case LEFT:
				if (rightJustpressed) {
					curColumn = CENTER;
					changeItem();
				}
			case RIGHT:
				if (leftJustpressed) {
					curColumn = CENTER;
					changeItem();
				}
		}

		if (Controls.justPressed('back')) {
			selectedSomethin = true;
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(() -> new TitleState());
		}

		if (Controls.justPressed('accept') || (FlxG.mouse.justPressed && allowMouse)) {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			selectedSomethin = true;
			FlxG.mouse.visible = false;

			if (Settings.data.flashing) FlxFlicker.flicker(magenta, 1.1, .15, false);

			var item:FlxSprite;
			var option:String;
			switch (curColumn) {
				case CENTER:
					option = optionShit[curSelected];
					item = menuItems.members[curSelected];
				case LEFT:
					option = leftOption;
					item = leftItem;
				case RIGHT:
					option = rightOption;
					item = rightItem;
			}

			FlxFlicker.flicker(item, 1, .06, false, false, (_:FlxFlicker) -> {
				if (CharacterSelectionState.onPlayState && (option == 'story_mode' || option == 'freeplay')) CharacterSelectionState.onPlayState = false;

				switch (option) {
					case 'story_mode': FlxG.switchState(() -> new StoryMenuState());
					case 'freeplay': FlxG.switchState(() -> new FreeplayState());
					#if MODS_ALLOWED case 'mods': FlxG.switchState(() -> new ModsMenuState()); #end
					#if AWARDS_ALLOWED case 'awards': FlxG.switchState(() -> new AwardsState()); #end
					case 'credits': FlxG.switchState(() -> new CreditsState());
					case 'options':
						FlxG.switchState(() -> new OptionsState());
						OptionsState.onPlayState = false;
						if (PlayState.SONG != null) {
							PlayState.SONG.arrowSkin = PlayState.SONG.splashSkin = null;
							PlayState.stageUI = 'normal';
						}
				}
			});

			for (memb in menuItems) {
				if (memb == item) continue;
				FlxTween.tween(memb, {alpha: 0}, .4, {ease: FlxEase.quadOut});
			}
		}
		if (Controls.justPressed('debug_1')) {
			selectedSomethin = true;
			FlxG.mouse.visible = false;
			FlxG.switchState(() -> new states.editors.MasterEditorMenu());
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0) {
		if (change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);

		for (item in menuItems) {
			item.animation.play('idle');
			item.centerOffsets();
		}

		var curItem:FlxSprite;
		switch (curColumn) {
			case CENTER: curItem = menuItems.members[curSelected];
			case LEFT: curItem = leftItem;
			case RIGHT: curItem = rightItem;
		}
		curItem.animation.play('selected');
		curItem.centerOffsets();
		if (curColumn == CENTER) curItem.gameCenter(X);

		FlxG.sound.play(Paths.sound('scrollMenu'));
		camFollow.y = curItem.getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0);
	}
}
