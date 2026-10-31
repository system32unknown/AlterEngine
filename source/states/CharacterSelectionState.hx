package states;

import objects.Character;
import objects.HealthIcon;

class CharacterInSelect {
	public var forms:Array<CharacterForm>;
	public function new(forms:Array<CharacterForm>) {
		this.forms = forms;
	}
}

class CharacterForm {
	public var name:String;
	public var polishedName:String;

	public function new(name:String, polishedName:String) {
		this.name = name;
		this.polishedName = polishedName;
	}
}

/**
 * This is not from the D&B source code, it's completely made by LatestRelic825,
 * Modified by Altertoriel. (Ported to PE 1.0)
 * TODO: REWRITE CHARACTER SELECTION.
 */
class CharacterSelectionState extends MusicBeatState {
	var characters:Array<CharacterInSelect> = [
		new CharacterInSelect([new CharacterForm('bf', 'Boyfriend'), new CharacterForm('bf-pixel', 'Boyfriend (Pixel)'), new CharacterForm('bf-christmas', 'Boyfriend (Christmas)'), new CharacterForm('bf-holding-gf', 'Boyfriend and Girlfriend')]),
		new CharacterInSelect([new CharacterForm('bs', 'Baby Shark Ollie'), new CharacterForm('bs-pixel', 'Baby Shark Ollie (Pixel)'), new CharacterForm('alter-holding-bs', 'Baby Shark Ollie And Altertoriel')]),
		new CharacterInSelect([new CharacterForm('dave-player', 'Dave'),]),
		new CharacterInSelect([new CharacterForm('bambi-player', 'Bambi'),]),
		new CharacterInSelect([new CharacterForm('tristan', 'Tristan'), new CharacterForm('tristan-golden', 'Golden Tristan')]),
		new CharacterInSelect([new CharacterForm('cheating-player', 'Expunged (Cheating)'), new CharacterForm('unfair-player', 'Expunged (Unfair)'), new CharacterForm('true-expunged-player', 'Expunged (True form)')]),
		new CharacterInSelect([new CharacterForm('pico-player', 'Pico')]),
		new CharacterInSelect([new CharacterForm('nate-player', 'Nate')]),
	];
	static var unlockedChrs:Array<String> = [];

	var current:Int = 0;
	var curForm:Int = 0;

	var boyfriendGroup:FlxSpriteGroup;
	var char:Character;

	var gfGroup:FlxSpriteGroup;
	var gf:Character;

	public static var characterFile:String = 'bf';
	public static var onPlayState:Bool = false;

	final BF_POS:Array<Float> = [770, 100];
	final GF_POS:Array<Float> = [400, 130];

	var characterText:FlxText;
	var curIcon:HealthIcon;
	var controlsText:FlxText;

	final noGFtext:String = 'No GF Skin: {1} [TAB]';

	var noGFSkin:Bool = false;
	var selectedCharacter:Bool = false;
	var pressedTheFunny:Bool = false;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var currentSelectedCharacter:CharacterInSelect;

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence('Selecting Character'); #end

		unlockedChrs = Settings.data.unlockedCharacters;
		unlockedChrs ??= []; // avoid null crashes

		persistentUpdate = true;

		camGame = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		var lastLoaded:String = Paths.currentLevel;
		Paths.currentLevel = 'week1';
		new states.stages.StageWeek1();
		camGame.scroll.set(120, 130);

		camGame.zoom = camHUD.zoom = .75;

		gfGroup = new FlxSpriteGroup(GF_POS[0], GF_POS[1]);
		boyfriendGroup = new FlxSpriteGroup(BF_POS[0], BF_POS[1]);

		gf = new Character(0, 0, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(.95, .95);
		gf.danceEveryNumBeats = 2;
		gfGroup.add(gf);

		char = new Character(0, 0, 'bf', true);
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
		boyfriendGroup.add(char);

		add(gfGroup);
		add(boyfriendGroup);

		var tutorialThing:FlxSprite = new FlxSprite(-125, -100, Paths.image('charSelectGuide'));
		tutorialThing.setGraphicSize(Std.int(tutorialThing.width * 1.25));
		tutorialThing.scrollFactor.set();
		tutorialThing.camera = camHUD;
		add(tutorialThing);

		characterText = new FlxText(0, -100, 0, "Boyfriend", 50);
		characterText.setFormat(Paths.font("comic.ttf"), 50, FlxColor.WHITE, CENTER);
		characterText.setBorderStyle(OUTLINE, FlxColor.BLACK, 5);
		characterText.camera = camHUD;
		characterText.scrollFactor.set();
		characterText.gameCenter(X);
		add(characterText);

		controlsText = new FlxText(-125, 125, 0, Language.getPhrase('nogf_mode', noGFtext, [noGFSkin]), 20);
		controlsText.setFormat(Paths.font("comic.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		controlsText.scrollFactor.set();
		controlsText.camera = camHUD;
		add(controlsText);

		curIcon = new HealthIcon(char.healthIcon, true);
		curIcon.scrollFactor.set();
		curIcon.gameCenter(X);
		curIcon.camera = camHUD;
		updateIconPosition();
		add(curIcon);

		if (unlockedChrs == null) currentSelectedCharacter = characters[current];
		Paths.currentLevel = lastLoaded;

		Conductor.bpm = 128;
		FlxG.sound.playMusic(Paths.music('offsetSong'));

		super.create();
	}

	override public function beatHit() {
		super.beatHit();
		if (!selectedCharacter) {
			if (camGame.zoom < 1.35) camGame.zoom += .0075;
			if (curBeat % 2 == 0 && char != null) char.dance();
			gf.dance();
		}
	}

	override function update(elapsed) {
		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);

		camGame.zoom = FlxMath.lerp(.7, camGame.zoom, Math.exp(-elapsed * 3.125));

		if (Controls.justPressed('accept')) {
			if (isLocked(characters[current].forms[curForm].name)) {
				FlxG.camera.shake(.05, .1);
				FlxG.sound.play(Paths.sound('missnotes/missnote1'), .9);
				return;
			}

			if (pressedTheFunny) return;
			pressedTheFunny = true;

			selectedCharacter = true;
			if (!onPlayState) {
				if (char.hasAnimation('hey') && char.animation.getByName('hey') != null) char.playAnim('hey', true);
				else char.playAnim('singUP', true);
				if (gf.hasAnimation('cheer') && gf.animation.getByName('cheer') != null) gf.playAnim('cheer', true);

				FlxG.sound.playMusic(Paths.music('gameOverEnd'));

				FlxTimer.wait(1.9, () -> {
					@:privateAccess
					if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory) {
						trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
						Paths.freeGraphicsFromMemory();
					}

					setData();
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(() -> new PlayState());
					FlxG.sound.music.volume = 0;
				});
			} else {
				setData();
				data.StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(() -> new PlayState());
				FlxG.sound.music.volume = 0;
			}
		}

		if (!selectedCharacter) {
			if (FlxG.keys.justPressed.TAB) {
				noGFSkin = !noGFSkin;
				controlsText.text = Language.getPhrase('nogf_mode', noGFtext, [noGFSkin]);
			}
		}

		var leftJustPressed:Bool = Controls.justPressed('ui_left');
		var downJustPressed:Bool = Controls.justPressed('ui_down');
		if (!selectedCharacter) {
			if (leftJustPressed || Controls.justPressed('ui_right')) {
				curForm = 0;
				current = FlxMath.wrap(current += (leftJustPressed ? -1 : 1), 0, characters.length - 1);
				updateBF();
			}

			if (downJustPressed || Controls.justPressed('ui_up')) {
				curForm = FlxMath.wrap(curForm += (downJustPressed ? -1 : 1), 0, characters[current].forms.length - 1);
				updateBF();
			}

			if (Controls.justPressed('reset')) {
				reset();
				FlxG.resetState();
			}
		}

		if (Controls.justPressed('back')) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (onPlayState) LoadingState.loadAndSwitchState(() -> new PlayState());
			else {
				FlxG.switchState(() -> new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		}
	}

	function setData():Void {
		if (!noGFSkin) PlayState.SONG.gfVersion = switch (characterFile) {
			case 'bf-pixel': 'gf-pixel';
			case 'bf-christmas': 'gf-christmas';
			case 'bs' | 'pico-player' | 'nate-player': 'gfbf';
			case 'bf-holding-gf': 'speaker';
			default: PlayState.SONG.gfVersion;
		}
		PlayState.SONG.player1 = characterFile;
	}

	public static function unlockCharacter(character:String, save:Bool = false) {
		if (!unlockedChrs.contains(character)) unlockedChrs.push(character);
		Settings.data.unlockedCharacters = unlockedChrs;
		if (save) Settings.save();
	}

	public static function isLocked(character:String):Bool {
		return !unlockedChrs.contains(character);
	}

	public static function reset() {
		Settings.data.unlockedCharacters = Settings.default_data.unlockedCharacters;
		Settings.save();
	}

	function updateBF() {
		FlxG.sound.play(Paths.sound('scrollMenu'), .4);

		currentSelectedCharacter = characters[current];
		characterText.text = currentSelectedCharacter.forms[curForm].polishedName;
		characterFile = currentSelectedCharacter.forms[curForm].name;

		char.destroy();
		boyfriendGroup.remove(char, true);
		char = new Character(0, 0, currentSelectedCharacter.forms[curForm].name, true);
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
		boyfriendGroup.add(char);

		curIcon.changeIcon(char.healthIcon);
		curIcon.color = FlxColor.WHITE;

		if (isLocked(characters[current].forms[curForm].name)) {
			char.color = FlxColor.BLACK;
			curIcon.color = FlxColor.BLACK;
			characterText.text = '???';
		}
		characterText.gameCenter(X);
		updateIconPosition();
	}

	function updateIconPosition() {
		var yValues:Array<Float> = utils.MathUtil.getMinAndMax(curIcon.height, characterText.height);
		curIcon.y = characterText.y - ((yValues[0] - yValues[1]) / 2);
	}
}