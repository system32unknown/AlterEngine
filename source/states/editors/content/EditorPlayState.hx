package states.editors.content;

import backend.Song;
import backend.Judgement;

import objects.*;
import utils.StringUtil;
import utils.SortUtil;

import flixel.FlxBasic;
import flixel.util.FlxSort;
import openfl.events.KeyboardEvent;

class EditorPlayState extends MusicBeatSubstate {
	// Borrowed from original PlayState
	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var inst:FlxSound = new FlxSound();
	var vocals:FlxSound;

	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<Note> = [];
	var judgeData:Array<Judgement> = Judgement.loadDefault();

	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	var combo:Int = 0;
	var keysArray:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	var noteGroup:FlxTypedGroup<FlxBasic>;

	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	var songSpeed:Float = 1;

	// Originals
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var scoreTxt:FlxText;
	var dataTxt:FlxText;

	var downScroll:Bool = Settings.data.downScroll;
	var middleScroll:Bool = Settings.data.middleScroll;

	var notesHitArray:Array<Date> = [];
	var nps:Int = 0;
	var maxNPS:Int = 0;

	var cpuControlled:Bool = false;
	
	var timeTxt:FlxText;
	var showTime:Bool = true;

	var _noteList:Array<Note>;
	public function new(noteList:Array<Note>, vocal:FlxSound) {
		super();

		/* setting up some important data */
		this.vocals = vocal;
		this._noteList = noteList;
		this.startPos = Conductor.songPosition;
		Conductor.songPosition = startPos;

		#if FLX_PITCH playbackRate = FlxG.sound.music.pitch; #end
	}

	override function create() {
		Conductor.safeZoneOffset = (Settings.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;

		/* borrowed from PlayState */
		if (Settings.data.hitsoundVolume > 0) Paths.sound('hitsounds/${Std.string(Settings.data.hitsoundTypes).toLowerCase()}');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF101010);
		bg.scrollFactor.set();
		bg.alpha = .9;
		bg.active = false;
		add(bg);

		/**** NOTES ****/
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		noteGroup = new FlxTypedGroup<FlxBasic>();

		timeTxt = new FlxText(0, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.gameCenter(X);
		timeTxt.visible = showTime;
		if (downScroll) timeTxt.y = FlxG.height - 44;
		add(timeTxt);

		add(noteGroup);
		noteGroup.add(strumLineNotes);

		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = .000001; // cant make it invisible or it won't allow precaching
		noteGroup.add(grpNoteSplashes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateStaticArrows(0);
		generateStaticArrows(1);

		scoreTxt = new FlxText(10, FlxG.height - 35, FlxG.width - 20, "", 16);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !Settings.data.hideHud;
		add(scoreTxt);

		dataTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
		dataTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		dataTxt.scrollFactor.set();
		dataTxt.borderSize = 1.25;
		add(dataTxt); dataTxt.updateHitbox();

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;

		generateSong();
		_noteList = null;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayState.SONG.song, true, songLength);
		#end
		updateScore();
		cachePopUpScore();

		super.create();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var totalCnt:Int = 0;
	override function update(elapsed:Float) {
		if (Controls.justPressed('back') || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.F12) {
			endSong();
			super.update(elapsed);
			return;
		}
		if (FlxG.keys.justPressed.SIX) cpuControlled = !cpuControlled;

		if (startingSong) {
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if (timerToStart < 0) startSong();
		} else {
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= 0) {
				var timeDiff:Float = Math.abs((inst.time + Conductor.offset) - Conductor.songPosition);
				Conductor.songPosition = FlxMath.lerp(inst.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 2.5));
				if (timeDiff > 1000 * playbackRate) Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}

		if (showTime) timeTxt.text = StringUtil.formatTime(Math.floor(Math.max(0, (Math.max(0, Conductor.songPosition - Settings.data.noteOffset) / playbackRate) / 1000))) + " / " + StringUtil.formatTime(Math.floor((songLength / playbackRate) / 1000));	

		if (unspawnNotes.length > totalCnt) {
			var targetNote:Note = unspawnNotes[totalCnt];
			while (targetNote.hitTime < spawnTime) {
				var dunceNote:Note = targetNote;
				dunceNote.spawned = true;

				dunceNote.strum = (!dunceNote.mustPress ? opponentStrums : playerStrums).members[dunceNote.noteData];
				notes.insert(0, dunceNote);
				++totalCnt;
				if (unspawnNotes.length > totalCnt) targetNote = unspawnNotes[totalCnt];
				else break;
			}
		}

		if (!cpuControlled) keysCheck();
		if (notes.length > 0) {
			notes.forEachAlive((daNote:Note) -> {
				daNote.followStrumNote(songSpeed / playbackRate);

				if (daNote.mustPress) {
					if (cpuControlled && !daNote.blockHit && daNote.canBeHit && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition)) goodNoteHit(daNote);
				} else if (!daNote.mustPress && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.strumTime <= Conductor.songPosition) opponentNoteHit(daNote);
				if (daNote.isSustainNote && daNote.strum.sustainReduce) daNote.clipToStrumNote();

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition - daNote.strumTime > noteKillOffset) {
					if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);
					daNote.active = daNote.visible = false;
					invalidateNote(daNote);
				}
			});
		}

		if (Settings.data.showNPS) {
			for (i in 0...notesHitArray.length) {
				var curNPS:Date = notesHitArray[i];
				if (curNPS != null && curNPS.getTime() + (1000 / playbackRate) < Date.now().getTime()) notesHitArray.remove(curNPS);
			}
			nps = Math.floor(notesHitArray.length);
			if (nps > maxNPS) maxNPS = nps;
			updateScore();
		}

		dataTxt.text = 'Section:$curSection\nBeat:$curBeat\nStep:$curStep\nBotplay:${(cpuControlled ? 'ON' : 'OFF')}';
		super.update(elapsed);
	}

	var lastBeatHit:Int = -1;
	override function beatHit() {
		if (lastBeatHit >= curBeat) return;
		notes.sort(FlxSort.byY, downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		super.beatHit();
		lastBeatHit = curBeat;
	}

	override function sectionHit() {
		var curSecNote:Section = PlayState.SONG.notes[curSection];
		if (curSecNote != null && curSecNote.changeBPM)
			Conductor.bpm = curSecNote.bpm;
		super.sectionHit();
	}

	override function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.mouse.visible = true;
		NoteSplash.configs.clear();
		FlxG.sound.list.remove(inst);
		flixel.util.FlxDestroyUtil.destroy(inst);
		super.destroy();
	}

	function startSong():Void {
		startingSong = false;
		@:privateAccess inst.load(FlxG.sound.music._sound);
		inst.looped = false;
		inst.onFinish.add(finishSong);
		inst.volume = vocals.volume = 1;
		FlxG.sound.list.add(inst);

		FlxG.sound.music.pause();
		inst.play(); vocals.play();
		inst.time = vocals.time = startPos - Conductor.offset;

		songLength = inst.length; // Song duration in a float, useful for the time left feature
	}

	// Borrowed from PlayState
	function generateSong() {
		songSpeed = switch (Settings.getGameplaySetting('scrolltype')) {
			case 'multiplied': PlayState.SONG.speed * Settings.getGameplaySetting('scrollspeed');
			case 'constant': songSpeed = Settings.getGameplaySetting('scrollspeed');
			default: PlayState.SONG.speed;
		}

		var songData:SwagSong = PlayState.SONG;
		Conductor.bpm = songData.bpm;
		inst.volume = vocals.volume = 0;

		noteGroup.add(notes = new FlxTypedGroup<Note>());

		var daBpm:Float = (PlayState.SONG.notes[0].changeBPM == true) ? PlayState.SONG.notes[0].bpm : PlayState.SONG.bpm;
		var oldNote:Note = null;
		var songNotes:Array<Dynamic> = [];

		// Section Time/Crochet
		var noteSec:Int = 0;
		var secTime:Float = 0;
		var cachedSectionTimes:Array<Float> = [];
		var cachedSectionCrochets:Array<Float> = [];
		if (PlayState.SONG != null) {
			var tempBpm:Float = daBpm;
			for (_ => section in PlayState.SONG.notes) {
				if (PlayState.SONG.notes[noteSec].changeBPM == true) tempBpm = PlayState.SONG.notes[noteSec].bpm;
				secTime += Conductor.calculateCrochet(tempBpm) * (Math.round(4 * section.sectionBeats) / 4);
				cachedSectionTimes.push(secTime);
			}
		}

		Note.chartArrowSkin = PlayState.SONG.arrowSkin;

		// Load Notes
		var section:Section = songData.notes[0];
		for (note in _noteList) {
			if (note == null || note.strumTime < startPos) continue;

			while (cachedSectionTimes.length > noteSec + 1 && cachedSectionTimes[noteSec + 1] <= note.strumTime) {
				section = songData.notes[++noteSec];
				if (PlayState.SONG.notes[noteSec].changeBPM == true)
					daBpm = PlayState.SONG.notes[noteSec].bpm;
			}

			var swagNote:Note = new Note(note.strumTime, note.noteData, oldNote, false, this);
			swagNote.mustPress = note.mustPress;
			swagNote.sustainLength = note.sustainLength;
			swagNote.gfNote = note.gfNote;
			swagNote.noteType = note.noteType;
			swagNote.scrollFactor.set();
			swagNote.updateSkin();
			unspawnNotes.push(swagNote);

			var curStepCrochet:Float = 60 / daBpm * 1000 / 4.;
			final roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet);
			if (roundSus > 0) {
				for (susNote in 0...roundSus) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					var sustainNote:Note = new Note(swagNote.strumTime + (curStepCrochet * susNote), note.noteData, oldNote, true, this);
					sustainNote.mustPress = swagNote.mustPress;
					sustainNote.gfNote = swagNote.gfNote;
					sustainNote.noteType = swagNote.noteType;
					sustainNote.scrollFactor.set();
					sustainNote.parent = swagNote;
					unspawnNotes.push(sustainNote);
					swagNote.tail.push(sustainNote);
					sustainNote.updateSkin();
					sustainNote.correctionOffset = swagNote.height / 2;
					if (oldNote.isSustainNote) {
						oldNote.sustainScale = (Note.SUSTAIN_SIZE / oldNote.frameHeight) / playbackRate;
						if (oldNote.sustainScale != 1) oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
					}
					if (downScroll) sustainNote.correctionOffset = 0;
					if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
					else if (middleScroll) {
						sustainNote.x += 310;
						if (sustainNote.noteData > 1) sustainNote.x += FlxG.width / 2 + 25; // Up and Right
					}
				}
			}
			if (swagNote.mustPress) swagNote.x += FlxG.width / 2; // general offset
			else if (middleScroll) {
				swagNote.x += 310;
				if (swagNote.noteData > 1) swagNote.x += FlxG.width / 2 + 25; // Up and Right
			}
			oldNote = swagNote;
		}
		unspawnNotes.sort(SortUtil.byStrumTime);
	}

	function generateStaticArrows(player:Int):Void {
		var strumLine:FlxPoint = FlxPoint.get(middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, downScroll ? (FlxG.height - 150) : 50);
		for (i in 0...4) {
			var targetAlpha:Float = 1;
			if (player < 1) {
				if (!Settings.data.opponentStrums) targetAlpha = 0;
				else if (middleScroll) targetAlpha = .35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLine.x, strumLine.y, i, player);
			babyArrow.downScroll = downScroll;
			babyArrow.alpha = targetAlpha;

			if (player < 1 && middleScroll) {
				babyArrow.x += 310;
				if (i > 1) babyArrow.x += FlxG.width / 2 + 25; // Up and Right
			}

			(player == 1 ? playerStrums : opponentStrums).add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
		strumLine.put();
	}

	public function finishSong():Void {
		if (Settings.data.noteOffset <= 0) endSong();
		else finishTimer = FlxTimer.wait(Settings.data.noteOffset / 1000, () -> endSong());
	}

	public function endSong() {
		notes.forEachAlive((note:Note) -> invalidateNote(note));
		for (note in unspawnNotes) if (note != null) invalidateNote(note);
		unspawnNotes.resize(0);

		inst.pause();
		vocals.pause();
		if (finishTimer != null) finishTimer.destroy();
		Conductor.songPosition = inst.time = vocals.time = startPos - Conductor.offset;
		close();
	}

	function cachePopUpScore() {
		var uiFolder:String = "";
		if (PlayState.stageUI != "normal") uiFolder = PlayState.uiPrefix + "UI/";

		for (judge in judgeData) Paths.image(uiFolder + 'judgements/${judge.image}'+ PlayState.uiPostfix);
		for (i in 0...10) Paths.image(uiFolder + 'judgements/number/num$i' + PlayState.uiPostfix);
	}

	function popUpScore(note:Note = null):Void { 
		var noteDiff:Float = PlayState.getNoteDiff(note) / playbackRate;
		var daRating:Judgement = Judgement.getTiming(noteDiff, cpuControlled);

		note.ratingMod = daRating.ratingMod;
		note.rating = daRating.name;

		if (!note.ratingDisabled) daRating.hits++;
		if (Settings.data.splashAlpha != 0 && daRating.noteSplash && !note.noteSplashData.disabled) spawnNoteSplashOnNote(note);

		if (!note.ratingDisabled) songHits++;
	}

	function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:flixel.input.keyboard.FlxKey = event.keyCode;
		if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(Controls.convertStrumKey(keysArray, eventKey));
	}

	function keyPressed(key:Int) {
		if (cpuControlled || key < 0 || key > playerStrums.length) return;

		var lastTime:Float = Conductor.songPosition; // more accurate hit time for the ratings?
		if (Conductor.songPosition >= 0) Conductor.songPosition = inst.time + Conductor.offset;

		// obtain notes that the player can hit

		var plrInputNotes:Array<Note> = notes.members.filter((n:Note) -> return n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit && !n.isSustainNote && n.noteData == key);
		plrInputNotes.sort((a:Note, b:Note) -> Std.int(a.strumTime - b.strumTime));

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note
			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.) invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime) funnyNote = doubleNote;
				}
			}

			goodNoteHit(funnyNote);
		}
		Conductor.songPosition = lastTime;

		final spr:StrumNote = playerStrums.members[key];
		if (spr != null && spr.animation.curAnim.name != 'confirm') {
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	function onKeyRelease(event:KeyboardEvent):Void {
		var key:Int = Controls.convertStrumKey(keysArray, event.keyCode);
		if (key > -1) keyReleased(key);
	}

	function keyReleased(key:Int) {
		if (cpuControlled || key < 0 || key > playerStrums.length) return;

		var spr:StrumNote = playerStrums.members[key];
		if (spr != null) {
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}

	// Hold notes
	function keysCheck():Void {
		var holdArray:Array<Bool> = [for (key in keysArray) Controls.pressed(key)];
		if (notes.length > 0) for (n in notes) if ((n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit) && n.isSustainNote && holdArray[n.noteData]) goodNoteHit(n);
	}

	function opponentNoteHit(note:Note):Void {
		if (PlayState.SONG.needsVoices) vocals.volume = 1;
		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000);
		note.hitByOpponent = true;
		if (!note.isSustainNote) invalidateNote(note);
	}

	function goodNoteHit(note:Note):Void {
		if (note.wasGoodHit || (cpuControlled && note.ignoreNote)) return;

		note.wasGoodHit = true;
		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound('${note.hitsound}'), note.hitsoundVolume);

		if (note.hitCausesMiss) {
			noteMiss(note);
			if (!note.isSustainNote) {
				if (Settings.data.splashAlpha != 0 && !note.noteSplashData.disabled) spawnNoteSplashOnNote(note);
				invalidateNote(note);
			} 
			return;
		}

		if (!note.isSustainNote) {
			notesHitArray.push(Date.now());
			combo++;
			popUpScore(note);
		}

		strumPlayAnim(false, note.noteData % 4, cpuControlled ? Conductor.stepCrochet * 1.25 / 1000 : 0);
		vocals.volume = 1;

		if (!note.isSustainNote) invalidateNote(note);
	}
	
	function noteMiss(daNote:Note):Void { // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if (daNote.animation.curAnim.name.endsWith("end")) return;

		songMisses++; // score and data
		updateScore();
		vocals.volume = 0;
		combo = 0;
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	function spawnNoteSplashOnNote(note:Note) {
		if (note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null) spawnNoteSplash(note, strum);
		}
	}

	function spawnNoteSplash(note:Note, strum:StrumNote) {
		var splash:NoteSplash = new NoteSplash();
		splash.babyArrow = strum;
		splash.spawnSplashNote(note);
		grpNoteSplashes.add(splash);
	}

	function updateScore():Void {
		scoreTxt.text = '${!Settings.data.showNPS ? '' : 'NPS: $nps/$maxNPS | '}' + 'Hits: $songHits | Misses: $songMisses';
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float = 0):Void {
		if (!Settings.data.lightStrum) return;
		var spr:StrumNote = (isDad ? opponentStrums : playerStrums).members[id];
		if (spr != null && Settings.data.lightStrum) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time / playbackRate;
		}
	}
}