package backend;

import options.GameplaySettingsSubState;

class MusicBeatState extends flixel.FlxState {
	static var currentState:MusicBeatState;

	var curSection:Int = 0;
	var stepsToDo:Int = 0;

	var oldStep:Int = 0;
	var varStep:Int = 0;
	var curStep:Int = 0;
	var curBeat:Int = 0;

	var curStepLimit:Int = 0;
	var updateCount:Int = 0;

	var curDecStep:Float = 0;
	var curDecBeat:Float = 0;

	var _psychCameraInitialized:Bool = false;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static function getVariables():Map<String, Dynamic> {
		var state:MusicBeatState = getState();
		return state?.variables ?? ([]:Map<String, Dynamic>);
	}

	var maxBPM:Float = 0;
	override function create():Void {
		currentState = this;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if (!_psychCameraInitialized) initPsychCamera();
		super.create();

		refreshMaxBPM();

		if (!skipNextTransOut) openSubState(new Transition(.5, true));
		skipNextTransOut = false;
	}

	override function destroy():Void {
		if (!Settings.data.disableGC) utils.system.MemoryUtil.clearMajor(true);
		super.destroy();
	}

	public function initPsychCamera():PsychCamera {
		var camera:PsychCamera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	var countJudge:Bool = false;
	var isFirstSection:Bool = false;
	override function update(elapsed:Float):Void {
		updateCount = 0;

		oldStep = curStep;
		varStep = oldStep + 1;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep) {
			isFirstSection = curStep >= 0 && oldStep < 0;

			if (curStep > 0 || isFirstSection) {
				stepHit();
				if (isFirstSection && PlayState.SONG != null) sectionHit();
			}

			if (PlayState.SONG != null) {
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}

		stagesFunc((stage:BaseStage) -> stage.update(elapsed));
		super.update(elapsed);
	}

	function updateSection():Void {
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo) {
			curSection++;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			sectionHit();
		}
	}

	function rollbackSection():Void {
		if (curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;

		for (i in 0...PlayState.SONG.notes.length) {
			if (PlayState.SONG.notes[i] == null) continue;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			if (stepsToDo > curStep) break;
			curSection++;
		}

		if (curSection > lastSection) sectionHit();
	}

	function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	function updateCurStep():Void {
		var lastChange:Conductor.BPMChangeEvent = Conductor.getBPMChangeFromMS(Conductor.songPosition);
		var elapsed:Float = ((Conductor.songPosition - Settings.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + elapsed;
		curStep = lastChange.stepTime + Math.floor(elapsed);
	}

	public static var transDirection:flixel.util.FlxAxes = X;
	override function startOutro(onOutroComplete:()->Void):Void {
		if (!skipNextTransIn) {
			FlxG.state.openSubState(new Transition(.5, false, transDirection));
			Transition.finishCallback = onOutroComplete;
			return;
		}

		skipNextTransIn = false;
		onOutroComplete();
	}

	public static function getState():MusicBeatState {
		if (Std.isOfType(FlxG.state, MusicBeatState))
			return cast(FlxG.state, MusicBeatState);
		return currentState;
	}

	public var stages:Array<BaseStage> = [];

	public function stepHit():Void {
		refreshMaxBPM();

		var nextStep:Float = curStep + 1;

		if (Conductor.bpm <= maxBPM) {
			countJudge = shouldCatchUp(nextStep);
			while (countJudge) {
				stagesFunc((stage:BaseStage) -> {
					stage.curStep = varStep;
					stage.curDecStep = curDecStep;
					stage.stepHit();
				});

				if (varStep % 4 == 0) beatHit();
				++varStep; ++updateCount;
				countJudge = shouldCatchUp(nextStep);
			}
		} else {
			stagesFunc((stage:BaseStage) -> {
				stage.curStep = varStep;
				stage.curDecStep = curDecStep;
				stage.stepHit();
			});

			if (curStep % 4 == 0) beatHit();
			updateCount = curStepLimit;
		}
	}

	public function beatHit():Void {
		stagesFunc((stage:BaseStage) -> {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void {
		stagesFunc((stage:BaseStage) -> {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void):Void {
		for (stage in stages) {
			if (stage == null || !stage.exists || !stage.active) continue;
			func(stage);
		}
	}

	function getBeatsOnSection():Int {
		var val:Null<Int> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val ?? 4;
	}

	/**
	 * Refreshes the stage, by redoing the render order of all props.
	 * It does this based on the `zIndex` of each prop.
	 */
	public function refresh():Void {
		sort(utils.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
	}

	function refreshMaxBPM():Void {
		curStepLimit = Settings.data.updateStepLimit;
		maxBPM = curStepLimit > 0 ? curStepLimit * GameplaySettingsSubState.defaultBPM * Settings.data.framerate : Math.POSITIVE_INFINITY;
	}

	inline function shouldCatchUp(nextStep:Float):Bool {
		return curStepLimit != 0 ? varStep < nextStep && updateCount < curStepLimit : varStep < nextStep;
	}
}