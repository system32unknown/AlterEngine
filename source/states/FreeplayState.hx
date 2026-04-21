package states;

import flixel.util.FlxDestroyUtil;
import haxe.Exception;
import haxe.Timer;

import data.WeekData;
import utils.FlxInterpolateColor;
import utils.system.MemoryUtil;
import utils.MathUtil;
import backend.Highscore;
import backend.Song;
import objects.HealthIcon;
import objects.MusicPlayer;
import substates.FreeplaySectionSubstate;

typedef SongMetadata = {
	name:String,
	week:Int,
	icon:String,
	color:Int,
	folder:String,
	lastDifficulty:String
}

class FreeplayState extends MusicBeatState {
	var songs:Array<SongMetadata> = [];

	static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var comboText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var intendedcombo:String = '';

	var grpSongs:FlxTypedGroup<Alphabet>;
	var grpIcons:FlxTypedGroup<HealthIcon>;

	var bg:FlxSprite;
	var interpColor:FlxInterpolateColor;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var loadingTextBG:FlxSprite;
	var loadingText:FlxText;
	var loading:Int = 0;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;

	public static var section:String = '';

	override function create() {
		if (Settings.data.disableGC) {
			MemoryUtil.compact();
			MemoryUtil.enable(false);
		}

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles();

		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Freeplay Menu", 'Section: $section'); #end

		section = FreeplaySectionSubstate.daSection;
		if (section == null || section == '') section = 'Vanilla';

		if (WeekData.weeksList.length < 1) {
			MusicBeatState.skipNextTransIn = true;
			persistentUpdate = false;
			FlxG.switchState(() -> new ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				() -> FlxG.switchState(() -> new states.editors.WeekEditorState()),
				() -> {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxG.switchState(() -> new MainMenuState());
				})
			);
			return;
		}

		var foundSection:Bool = false;
		for (i in 0...WeekData.weeksList.length) {
			if (weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if (leWeek.section != null) {
				if (leWeek.section != section) foundSection = true;
				else foundSection = false;
			} else foundSection = true;

			if (foundSection) {
				foundSection = false;
				continue;
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs) {
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3) colors = [146, 113, 253];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		add(bg = new FlxSprite(Paths.image('menuDesat')));
		bg.antialiasing = Settings.data.antialiasing;
		bg.gameCenter();

		add(grpSongs = new FlxTypedGroup<Alphabet>());
		add(grpIcons = new FlxTypedGroup<HealthIcon>());

		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * .7, 5, 0, '', 32);
		scoreText.font = Paths.font('babyshark.ttf');
		scoreText.alignment = RIGHT;
		scoreText.visible = false;

		add(scoreBG = new FlxSprite(scoreText.x - 6).makeGraphic(1, 90, FlxColor.BLACK));
		scoreBG.visible = false;
		scoreBG.alpha = 0.6;

		add(scoreText);

		add(diffText = new FlxText(scoreText.x, 0, 0, '', 24));
		diffText.y = scoreBG.height - diffText.height + 10;
		diffText.font = scoreText.font;
		diffText.visible = false;
		add(comboText = new FlxText(scoreText.x, scoreBG.height / 2 - 6, 0, '', 24));
		comboText.font = diffText.font;

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = .6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '');
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		loadingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		loadingTextBG.alpha = 0.6;
		loadingTextBG.visible = true;
		add(loadingTextBG);

		loadingText = new FlxText(0, 0, FlxG.width, '');
		loadingText.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		loadingText.scrollFactor.set();
		loadingText.visible = true;
		add(loadingText);

		if (curSelected >= songs.length) curSelected = 0;
		interpColor = new FlxInterpolateColor(bg.color);
		lerpSelected = curSelected;
		
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		var leText:String = Language.getPhrase("freeplay_tip", '[SPACE] Listen to the Song • [CTRL] Gameplay Changers Menu • [HOLD TAB] Character Selection\n[COMMA] Change Sections • [RESET] Reset Score and Accuracy');
		bottomString = leText;
		bottomText = new FlxText(0, 0, FlxG.width, leText, 18);
		bottomText.font = Paths.font("babyshark.ttf");
		bottomText.alignment = CENTER;
		bottomText.scrollFactor.set();
		bottomText.y = FlxG.height - bottomText.height;
		bottomText.visible = false;
		add(bottomText);

		bottomBG = new FlxSprite().makeGraphic(FlxG.width, Std.int(bottomText.height), 0x7F000000);
		bottomBG.scrollFactor.set();
		bottomBG.y = FlxG.height - bottomBG.height;
		bottomBG.visible = false;
		insert(members.indexOf(bottomText), bottomBG);

		add(player = new MusicPlayer(this));

		changeSelection();
		updateTexts();
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	function loadSong(index:Int):Void {
		var song:SongMetadata = songs[index];

		var songText:Alphabet = grpSongs.add(new Alphabet(90, 320, song.name));
		songText.targetY = index;
		songText.scaleX = Math.min(1, 980 / songText.width);
		songText.snapToPosition();

		Mods.currentModDirectory = song.folder;
		
		var icon:HealthIcon = new HealthIcon(song.icon);
		icon.iconType = 'psych';
		icon.autoOffset = true;
		icon.sprTracker = songText;

		songText.visible = songText.active = songText.isMenuItem = false;
		icon.visible = icon.active = false;
		grpIcons.add(icon);
	}

	public function addSong(name:String, weekNum:Int, songCharacter:String, color:Int) {
		songs.push({
			name: name,
			week: weekNum,
			icon: songCharacter,
			color: color,
			folder: Mods.currentModDirectory ?? '',
			lastDifficulty: null
		});
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	var stopMusicPlay:Bool = false;

	var spamTime:Float = 0;
	var stampTime:Float = Timer.stamp();
	var delayTime:Float = Timer.stamp();
	override function update(elapsed:Float) {
		if (WeekData.weeksList.length < 1) {
			super.update(elapsed);
			return;
		}

		while (loading < songs.length) {
			loadSong(loading++);
			delayTime = Timer.stamp() - stampTime;
			if (delayTime > 1 / Settings.data.framerate || loading >= songs.length) {
				var curr:String = Std.string(loading);
				var total:String = Std.string(songs.length);
				var prog = MathUtil.floorDecimal(loading * 100.0 / songs.length, 1);

				loadingText.text = 'Loading Song...\n$curr / $total - $prog% Done';
				loadingText.gameCenter();

				stampTime = Timer.stamp();
				
				if (loading >= songs.length) {
					WeekData.setDirectoryFromWeek();
					loadingText.visible = loadingTextBG.visible = false;
					scoreText.visible = scoreBG.visible = diffText.visible = bottomBG.visible = bottomText.visible = true;

					if (Settings.data.disableGC && !MemoryUtil.isGcOn) {
						MemoryUtil.enable();
						MemoryUtil.collect(true);
					}

					changeSelection(0, true);
					updateTexts(delayTime);
				}

				super.update(delayTime);
				return;
			}
		}

		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		if (FlxG.sound.music.volume < .7) FlxG.sound.music.volume += .5 * elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));
		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= .01) lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(MathUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2) ratingSplit.push(''); //No decimals, add an empty space
		while (ratingSplit[1].length < 2) ratingSplit[1] += '0'; //Less than 2 decimals in it, add decimals then
		
		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!player.playingMusic) {
			scoreText.text = Language.getPhrase('high_score', 'HIGHSCORE: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
			comboText.text = Language.getPhrase('high_combo', 'RATING: {1}', [intendedcombo]);
			positionHighscore();

			if (songs.length > 1) {
				if (FlxG.keys.justPressed.HOME || FlxG.keys.justPressed.END) {
					curSelected = FlxG.keys.justPressed.HOME ? 0 : songs.length - 1;
					changeSelection();
					holdTime = 0;
				}

				final upPressed:Bool = Controls.pressed('ui_up');
				final upJustPressed:Bool = Controls.justPressed('ui_up');
				if (Controls.justPressed('ui_down') || upJustPressed) {
					changeSelection(upPressed ? -shiftMult : shiftMult);
					holdTime = 0;
				}

				if (Controls.pressed('ui_down') || upPressed) {
					holdTime += elapsed;
					if (holdTime > 0.5) {
						spamTime += elapsed;
						var timeLimit:Float = 1 / MathUtil.interpolate(10, 30, (holdTime - .5) / 5, 2);

						if (spamTime > timeLimit) {
							changeSelection(upPressed ? -shiftMult : shiftMult);
							spamTime -= timeLimit;
						}
					}
				}

				if (FlxG.mouse.wheel != 0) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			final leftJustPressed:Bool = Controls.justPressed('ui_left');
			if (leftJustPressed || Controls.justPressed('ui_right')) {
				changeDiff(leftJustPressed ? -1 : 1);
				_updateSongLastDifficulty();
			}
		}

		interpColor.fpsLerpTo(songs[curSelected].color, .0625);
		bg.color = interpColor.color;

		if (Controls.justPressed('back')) {
			if (player.playingMusic) {
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				if (Settings.data.disableGC) MemoryUtil.enable();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			} else {
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new MainMenuState());
			}
		}

		if (FlxG.keys.justPressed.CONTROL && !player.playingMusic) {
			persistentUpdate = false;
			openSubState(new options.GameplayChangersSubstate());
		} else if (FlxG.keys.justPressed.SPACE) {
			if (instPlaying != curSelected && !player.playingMusic) {
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var songLowercase:String = songs[curSelected].name.toLowerCase();
				var poop:String = Song.format(songLowercase, curDifficulty);

				try {
					if (Settings.data.disableGC) {
						MemoryUtil.enable();
						MemoryUtil.collect(true);
						MemoryUtil.enable(false);
					}
					Song.loadFromJson(poop, true, songLowercase);
				} catch (e:Exception) {
					if (Settings.data.disableGC) {
						MemoryUtil.enable();
						MemoryUtil.collect(true);
					}

					var errorStr:String = e.message;
					if (errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ${errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1)}'; //Missing chart
					else errorStr += '\n\n' + e.stack;

					missingText.text = 'ERROR WHILE LOADING SONG:\n$errorStr';
					missingText.gameCenter(Y);
					missingText.visible = missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					updateTexts(elapsed);
					super.update(elapsed);
					return;
				}
				if (PlayState.SONG.needsVoices) {
					vocals = new FlxSound();
					try {
						var loadedVocals:openfl.media.Sound = Paths.voices(PlayState.SONG.song);
						if (loadedVocals != null && loadedVocals.length > 0) {
							vocals.load(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = .8;
							vocals.play();
							vocals.pause();
						} else vocals = FlxDestroyUtil.destroy(vocals);
					} catch (e:Dynamic) vocals = FlxDestroyUtil.destroy(vocals);
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), .8);
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);
			} else if (instPlaying == curSelected && player.playingMusic) player.pauseOrResume(!player.playing);
		} else if (Controls.justPressed('accept') && !player.playingMusic) {
			persistentUpdate = false;
			var songFolder:String = Paths.formatToSongPath(songs[curSelected].name);
			var songLowercase:String = Song.format(songFolder, curDifficulty);

			if (songLowercase == "" || songLowercase.length < 1) return;

			try {
				if (Settings.data.disableGC) {
					MemoryUtil.enable();
					MemoryUtil.collect(true);
					MemoryUtil.enable(false);
				}
				Song.loadFromJson(songLowercase, false, songFolder);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
			} catch (e:Exception) {
				var errorStr:String = e.message;
				if (errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ${errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1)}'; //Missing chart
				else errorStr += '\n\n' + e.stack;

				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.gameCenter(Y);
				missingText.visible = missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}

			@:privateAccess
			if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory) {
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}

			if (FlxG.keys.pressed.TAB) FlxG.switchState(() -> new CharacterSelectionState());
			else {
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(() -> new PlayState());
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
			}
			stopMusicPlay = true;

			destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED) DiscordClient.loadModRPC(); #end
		} else if (FlxG.keys.justPressed.COMMA && !player.playingMusic) {
			persistentUpdate = false;
			openSubState(new FreeplaySectionSubstate());
			FlxG.sound.play(Paths.sound('scrollMenu'));
		} else if (Controls.justPressed('reset') && !player.playingMusic) {
			persistentUpdate = false;
			openSubState(new substates.ResetScoreSubState(songs[curSelected].name, curDifficulty, songs[curSelected].icon));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if (vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);
	}

	function changeDiff(change:Int = 0) {
		if (player.playingMusic) return;
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);

		intendedScore = Highscore.getScore(songs[curSelected].name, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].name, curDifficulty);
		intendedcombo = Highscore.getCombo(songs[curSelected].name, curDifficulty);

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1) diffText.text = '< ${displayDiff.toUpperCase()} >';
		else diffText.text = displayDiff.toUpperCase();

		positionHighscore();
		missingText.visible = missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true) {
		if (player.playingMusic || grpSongs.length == 0 || grpIcons.length == 0) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		_updateSongLastDifficulty();
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), .4);

		for (num => item in grpSongs.members) {
			var selectAlpha:Float = (num == curSelected ? 1 : .6);
			item.alpha = selectAlpha;
			grpIcons.members[num].alpha = selectAlpha;
		}

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();

		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if (savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if (lastDiff > -1) curDifficulty = lastDiff;
		else if (Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline function _updateSongLastDifficulty() {
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
	}

	function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
		comboText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		comboText.x -= comboText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0) {
		if (grpSongs.length == 0 || grpIcons.length == 0) return;

		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles) {
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			grpIcons.members[i].visible = grpIcons.members[i].active = false;
		}
		_lastVisibles.resize(0);

		var min:Int = Math.round(FlxMath.bound(lerpSelected - _drawDistance, 0, songs.length));
		var max:Int = Math.round(FlxMath.bound(lerpSelected + _drawDistance, 0, songs.length));
		for (i in min...max) {
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.spawnPos.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.spawnPos.y;

			var icon:HealthIcon = grpIcons.members[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	override function destroy():Void {
		super.destroy();

		FlxG.autoPause = Settings.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
}