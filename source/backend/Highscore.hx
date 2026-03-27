package backend;

import flixel.util.FlxSave;
import haxe.ds.StringMap;

enum SaveMode {
	WEEKSCORE;
	SCORE;
	RATING;
	COMBO;
	ALL;
}

class Highscore {
	public static var weekScores:StringMap<Int> = new StringMap<Int>();
	public static var songScores:StringMap<Int> = new StringMap<Int>();
	public static var songRating:StringMap<Float> = new StringMap<Float>();
	public static var songCombos:StringMap<String> = new StringMap<String>();

	static var _save:FlxSave;

	// RESET
	public static function resetSong(song:String, diff:Int = 0):Void {
		var key:String = Song.format(song, diff);
		songScores.remove(key);
		songRating.remove(key);
		songCombos.remove(key);
		save();
	}

	public static function resetWeek(week:String, diff:Int = 0):Void {
		weekScores.remove(Song.format(week, diff));
		save(WEEKSCORE);
	}

	// SAVE
	public static function saveScore(song:String, score:Int, diff:Int = 0, rating:Float = -1):Void {
		if (song == null) return;

		var key:String = Song.format(song, diff);
		var prev:Null<Int> = songScores.get(key);
		if (prev != null && score <= prev) return;

		songScores.set(key, score);
		save(SCORE);

		if (rating >= 0) {
			songRating.set(key, rating);
			save(RATING);
		}
	}

	public static function saveWeekScore(week:String, score:Int, diff:Int = 0):Void {
		var key:String = Song.format(week, diff);
		var prev:Null<Int> = weekScores.get(key);
		if (prev != null && score <= prev) return;

		weekScores.set(key, score);
		save(WEEKSCORE);
	}

	public static function saveCombo(song:String, combo:String, diff:Int = 0):Void {
		if (song == null) return;

		var key:String = Song.format(song, diff);
		if (getComboRank(combo) <= getComboRank(songCombos.get(key))) return;

		songCombos.set(key, sanitizeCombo(combo));
		save(COMBO);
	}

	// GETTERS
	public static function getScore(song:String, diff:Int):Int
		return songScores.get(Song.format(song, diff)) ?? 0;

	public static function getWeekScore(week:String, diff:Int):Int
		return weekScores.get(Song.format(week, diff)) ?? 0;

	public static function getRating(song:String, diff:Int):Float
		return songRating.get(Song.format(song, diff)) ?? 0;

	public static function getCombo(song:String, diff:Int):String
		return songCombos.get(Song.format(song, diff)) ?? "Unclear, N/A";

	static final COMBO_ORDER:Array<String> = ["Clear", "SDCB", "FC", "GFC", "SFC", "PFC"];

	static function getComboRank(combo:String):Int {
		if (combo == null) return 0;
		var idx:Int = COMBO_ORDER.indexOf(combo.split(",")[0]);
		return idx < 0 ? 0 : idx + 1;
	}

	static function sanitizeCombo(combo:String):String {
		return Util.notBlank(combo) ? combo : "Unclear, N/A";
	}

	public static function load():Void {
		_save = new FlxSave();
		_save.bind("scores", Util.getSavePath());

		if (_save.data.weekScores != null) weekScores = _save.data.weekScores;
		if (_save.data.songScores != null) songScores = _save.data.songScores;
		if (_save.data.songRating != null) songRating = _save.data.songRating;
		if (_save.data.songCombos != null) songCombos = _save.data.songCombos;
	}

	public static function save(savemode:SaveMode = ALL):Void {
		if (_save == null) return;

		switch (savemode) {
			case WEEKSCORE: _save.data.weekScores = weekScores;
			case SCORE: _save.data.songScores = songScores;
			case RATING: _save.data.songRating = songRating;
			case COMBO: _save.data.songCombos = songCombos;
			case ALL:
				_save.data.weekScores = weekScores;
				_save.data.songScores = songScores;
				_save.data.songRating = songRating;
				_save.data.songCombos = songCombos;
		}
		_save.flush();
	}
}