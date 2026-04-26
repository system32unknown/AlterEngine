package substates;

import flixel.FlxObject;
import objects.Character;

class GameOverSubstate extends MusicBeatSubstate {
	public var boyfriend:Character;
	var camFollow:FlxObject;

	public var camOther:FlxCamera;
	public var camHUD:FlxCamera;

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var deathDelay:Float = 0;

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		deathDelay = 0;

		var song:backend.Song.SwagSong = PlayState.SONG;
		if (song == null) return;

		inline function useIfNonEmpty(v:String, fallback:String):String {
			return (v != null && v.trim().length > 0) ? v : fallback;
		}

		characterName = useIfNonEmpty(song.gameOverChar, characterName);
		deathSoundName = useIfNonEmpty(song.gameOverSound, deathSoundName);
		loopSoundName = useIfNonEmpty(song.gameOverLoop, loopSoundName);
		endSoundName = useIfNonEmpty(song.gameOverEnd, endSoundName);
	}

	public static function cache():Void {
		Paths.sound(deathSoundName);
		Paths.music(loopSoundName);
		Paths.music(endSoundName);

		var ins:PlayState = PlayState.instance;
		if (ins != null) ins.gameOverChar = new Character(0, 0, characterName, true);
	}

	override function create() {
		instance = this;

		if (!Settings.data.disableGC) utils.system.MemoryUtil.clearMajor(true);

		var ins:PlayState = PlayState.instance;

		FlxG.sound.play(Paths.sound(deathSoundName));

		boyfriend = getBoyfriend(ins);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriend.skipDance = true;
		add(boyfriend);

		// Camera refs (guard just in case)
		if (ins != null) {
			camOther = ins.camOther;
			camHUD = ins.camHUD;
			resetExtraCameras();
		}

		Conductor.songPosition = 0;
		Conductor.bpm = 100;

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		// Start death anim once, and transition to loop when finished.
		startDeathSequence();

		// Follow target
		camFollow = new FlxObject(0, 0, 1, 1);
		positionCamFollow();
		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		add(camFollow);

		// HScript hooks
		ins.setOnHScript('inGameOver', true);
		ins.callOnHScript('onGameOverStart');

		super.create();
	}

	function resetExtraCameras() {
		if (camOther != null) {
			camOther.zoom = 1;
			camOther.setPosition();
			camOther.angle = 0;
		}
		if (camHUD != null) {
			camHUD.zoom = 1;
			camHUD.setPosition();
			camHUD.angle = 0;
		}
	}

	function startDeathSequence() {
		// Put first frame immediately if available (prevents popping)
		var anim:flixel.animation.FlxAnimation = boyfriend.animation.getByName('firstDeath');
		boyfriend.playAnim('firstDeath');
		if (anim != null && anim.frames != null && anim.frames.length > 0) {
			boyfriend.animation.frameIndex = anim.frames[0];
		}

		// When firstDeath ends, loop + start music once.
		boyfriend.animation.onFinish.add((name:String) -> {
			if (name == 'firstDeath' && !isEnding) {
				boyfriend.playAnim('deathLoop');
				FlxG.sound.playMusic(Paths.music(loopSoundName));
			}
			boyfriend.animation.onFinish.removeAll();
		});
	}

	function positionCamFollow() {
		if (boyfriend == null) return;

		final mid:FlxPoint = boyfriend.getGraphicMidpoint();
		camFollow.setPosition(mid.x + boyfriend.cameraPosition[0], mid.y + boyfriend.cameraPosition[1]);
		mid.put();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		PlayState.instance.callOnHScript('onUpdate', [elapsed]);

		// Keep follow point updated if character moves (some mods do)
		positionCamFollow();

		if (!isEnding) {
			if (Controls.justPressed('accept')) endBullshit();
			else if (Controls.justPressed('back')) exitToMenu();

			if (FlxG.sound.music != null && FlxG.sound.music.playing) Conductor.songPosition = FlxG.sound.music.time;
		}

		PlayState.instance.callOnHScript('onUpdatePost', [elapsed]);
	}

	function exitToMenu() {
		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

		FlxG.camera.visible = false;
		FlxG.sound.music.stop();

		PlayState.deathCounter = 0;
		PlayState.seenCutscene = false;
		PlayState.chartingMode = false;

		Mods.loadTopMod();
		FlxG.switchState(() -> PlayState.isStoryMode ? new states.StoryMenuState() : new states.FreeplayState());
		FlxG.sound.playMusic(Paths.music('freakyMenu'));

		PlayState.instance.callOnHScript('onGameOverConfirm', [false]);
	}

	override function destroy() {
		instance = null;
		super.destroy();
	}

	var isEnding:Bool = false;

	function endBullshit():Void {
		if (isEnding) return;
		isEnding = true;

		if (boyfriend.hasAnimation('deathConfirm')) boyfriend.playAnim('deathConfirm', true);
		else if (boyfriend.hasAnimation('deathLoop')) boyfriend.playAnim('deathLoop', true);

		FlxG.sound.music.stop();

		var snd:FlxSound = FlxG.sound.play(Paths.music(endSoundName));
		FlxTimer.wait(.7, () -> {
			FlxG.camera.fade(FlxColor.BLACK, 2);
			FlxTimer.wait((snd.length / 1000) - .7, () -> {
				MusicBeatState.skipNextTransIn = true;

				PlayState.instance?.unloadNotes();
				FlxG.resetState();
			});
		});

		PlayState.instance.callOnHScript('onGameOverConfirm', [true]);
	}

	function getBoyfriend(ins:PlayState):Character {
		// Safe fallbacks if PlayState is missing
		if (ins == null || ins.boyfriend == null) {
			return new Character(0, 0, characterName, true);
		}

		final pos:FlxPoint = ins.boyfriend.getScreenPosition();
		var x:Float = pos.x - ins.boyfriend.positionArray[0];
		var y:Float = pos.y - ins.boyfriend.positionArray[1];
		pos.put();

		// Prefer cached gameOverChar
		var bf:Character = ins.gameOverChar;
		if (bf != null && bf.curCharacter == characterName) {
			bf.setPosition(x, y);
			return bf;
		}

		// Then map cache
		bf = ins.boyfriendMap != null ? ins.boyfriendMap.get(characterName) : null;
		if (bf != null) {
			bf.setPosition(x, y);
			bf.visible = true;
			return bf;
		}

		return new Character(x, y, characterName, true);
	}
}