package states.stages;

import states.stages.objects.*;

class StageWeek1 extends BaseStage {
	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleFog:DadBattleFog;

	override function create() {
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		bg.zIndex = 10;
		add(bg);

		final stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.zIndex = 20;
		add(stageFront);

		if (lowQuality) return;

		for (i in 0...2) {
			final stageLight:BGSprite = new BGSprite('stage_light', (i == 2 ? 1225 : -125), -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			stageLight.flipX = (i == 2);
			stageLight.zIndex = 30;
			add(stageLight);
		}

		final stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * .9));
		stageCurtains.updateHitbox();
		stageCurtains.zIndex = 30;
		add(stageCurtains);
	}

	override function eventPushed(event:objects.Note.EventNote) {
		switch (event.event) {
			case "Dadbattle Spotlight":
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				add(dadbattleLight);

				dadbattleFog = new DadBattleFog();
				dadbattleFog.visible = false;
				add(dadbattleFog);
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {
		switch (eventName) {
			case "Dadbattle Spotlight":
				if (flValue1 == null) flValue1 = 0;
				var val:Int = Math.round(flValue1);

				switch (val) {
					case 1, 2, 3: // enable and target dad
						if (val == 1) { // enable
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleFog.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:objects.Character = dad;
						if (val > 2) who = boyfriend; // 2 only targets dad
						dadbattleLight.alpha = 0;
						FlxTimer.wait(.12, () -> dadbattleLight.alpha = .375);
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
						FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= .12;
						FlxTween.tween(dadbattleFog, {alpha: 0}, .7, {onComplete: (twn:FlxTween) -> dadbattleFog.visible = false});
				}
		}
	}
}