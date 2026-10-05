package states;

import objects.AttachedSprite;
import utils.FlxInterpolateColor;

// TODO: REWRITE CREDITS MENU.
class CreditsState extends MusicBeatState {
	// Title, Variable, Description, Color
	static var titles(default, never):Array<Array<String>> = [
		['Credits Sections'],
		['Psych Engine Team',			'psych',			'Developers of Psych Engine',						'D662EB'],
		["Funkin' Crew",			'funkin',				'The only cool kickers of Friday Night Funkin\'',	'FD40AB'],
		["Vs Dave and Bambi Team",		'daveandbambi',		'Developers of Dave and Bambi',						'216AFF'],
		["Baby Shark's Big Funkin Team",	'babyshark',	'Developers of Baby Shark\'s Big Funkin',			'F8CB23'],
		['']
	];

	// Name - Icon name - Description - Link - BG Color
	static var psych(default, never):Array<Array<String>> = [
		['Psych Engine Team'],
		['Shadow Mario',		'shadowmario',		'Main Programmer and Head of Psych Engine',						'https://x.com/Shadow_Mario_',		'444444'],
		['Riveren',				'riveren',			'Main Artist/Animator of Psych Engine',							'https://x.com/riverennn',			'14967B'],
		[''],
		['Former Engine Members'],
		['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',								'https://x.com/bbsub3',				'3E813A'],
		[''],
		['Engine Contributors'],
		['crowplexus', 			'crowplexus', 		'Linux Support, Input System v3 and Other PRs', 				'https://x.com/IamMorwen', 			'CFCFCF'],
		['Keoiki',				'keoiki',			'Note Splash Animations and Latin Alphabet', 					'https://x.com/Keoiki_',			'D2D2D2'],
		['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',		'https://x.com/flicky_i',			'9E29CF'],
		['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',	'https://x.com/gedehari',			'E1843A'],
		['EliteMasterEric',		'mastereric',		'Runtime Shaders support',										'https://x.com/EliteMasterEric',	'FFBD40'],
		['Gabriela',			'gabriela',			'Playback Rate Modifier\nand other PRs',						'https://x.com/BeastlyGabi',		'5E99DF'],
		['MAJigsaw77', 			'jigsaw', 			'.MP4 Video Loader Library (hxvlc)', 							'https://x.com/MAJigsaw77', 		'5F5F5F'],
		['KadeDev',				'kade',				'Fixed Chart Editor\nand other PRs, Kade Engine Dev',			'https://x.com/kade0912',			'64A250'],
		['Raltyro',				'raltyro',			'Psike Engine Dev',												'https://x.com/raltyro',			'F3F3F3'],
		['UncertainProd',		'prod',				'Sampler2D in Runtime Shaders',									'https://github.com/UncertainProd',	'D2D2D2'],
		['ACrazyTown',			'acrazytown',		'Optimized PNGs',												'https://x.com/acrazytown',			'A03E3D'],
		['CheemsAndFriends', 	'cheems', 			'Creator of FlxAnimate', 										'https://x.com/CheemsnFriendos', 	'E1E1E1'],
		['Itz_Miles', 			'miles', 			'Linear GFX Transformations Library (ParallaxLT)', 				'https://x.com/Itz_MilesDev', 		'7AAAFE'],
		[''],
		['Special Thanks'],
		['Codename Engine',		'codename',			'Some stuffs used for this engine',				'https://github.com/CodenameCrew/CodenameEngine',	'FF9300'],
		['HRK-EXEX',			'hrk',				'Some stuffs used for this engine',				'https://github.com/HRK-EXEX',						'FF9300'],
	];

	static var funkin(default, never):Array<Array<String>> = [
		["Funkin' Crew"],
		['ninjamuffin99', 		'ninjamuffin99', 	"Programmer of Friday Night Funkin'", 							'https://x.com/ninja_muffin99', 	'F73838'],
		['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",								'https://x.com/PhantomArcade3K',	'FFBB1B'],
		['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",								'https://x.com/evilsk8r',			'53E52C'],
		['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",								'https://x.com/kawaisprite',		'6475F3']
	];

	static var daveandbambi(default, never):Array<Array<String>> = [
		['Vs Dave and Bambi Team'],
		['MoldyGH',				'MoldyGH',			'Creator / Main Dev',											'https://x.com/moldy_gh',			'FF2626'],
		['MTM101',				'MTM10',			'Secondary Dev',												'https://x.com/OfficialMTM101',		'FF00FF'],
		['Rapparep lol',		'rapparep',			'Main Artist',													'https://x.com/rappareplol',		'FF0000'],
		['TheBuilderXD',		'TheBuilderXD',		'Page Manager, Tristan Sprite Creator, and more',				'https://x.com/TheBuilderXD',		'CC6600'],
		['Erizur',				'Erizur',			'Programmer, Week Icon Artist',									'https://x.com/am_erizur',			'FFFFFF'],
		['Pointy',				'pointy',			'Artist & Charter',												'https://x.com/PointyyESM',			'0700FE'], 
		['Zmac',				'Zmac',				'3D Backgrounds, Intro text help',								'https://www.youtube.com/@ZmacRavioli','FFFFFF'], 
		['Billy Bobbo',			'billy',			'Moral Support & Idea Suggesting',								'https://x.com/BillyBobboLOL',		'FF0000'],
		['Steph45',				'Steph45',			'Minor programming, Moral support',								'https://x.com/Stats451',			'FFF729'],
		['T5mpler',				'T5mpler',			'Programmer & Supporter',										'https://x.com/RealT5mpler',		'363B59'],
	];

	static var babyshark(default, never):Array<Array<String>> = [
		['Baby Shark\'s Big Funkin Team'],
		['Altertoriel', 		'altertoriel',		'Main Developer', 													'https://x.com/Altertoriel2', 	'B9AF27'],
		['Pinkfong', 			'pinkfong', 		'Creator of Baby Shark', 											'https://pinkfong.com',			'F93FA2'],
		['Nickelodeon', 		'nickelodeon', 		'Creator of Baby Shark\'s Big Show / Baby Shark Ollie and William', 'https://www.nick.com',			'F57C13'],
	];

	public static var prevSelected:Int = 0;
	public var curSelected:Int = -1;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var sections:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var descBox:AttachedSprite;
	var interpColor:FlxInterpolateColor;

	final offsetThing:Float = -75;

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Credits"); #end

		sections = [for (title in titles) title];

		persistentUpdate = true;
		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.antialiasing = Settings.data.antialiasing;
		add(bg);
		bg.gameCenter();

		add(grpOptions = new FlxTypedGroup<Alphabet>());

		#if MODS_ALLOWED
		var activeMods:Array<String> = Mods.getActiveModDirectories(true);
		pushModCredits();
		for (mod in activeMods) pushModCredits(mod);

		if (modCredits.length > 0) {
			sections.push(['Modpack Credits Sections']);
			modSectionsBound = sections.length;
		}
		for (mod in modCredits) sections.push(mod);
		#end

		if (curSelected > sections.length || curSelected < 0)
			curSelected = -1;

		for (i in 0...sections.length) {
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 335, sections[i][0]);
			optionText.fieldWidth = FlxG.width;
			optionText.isMenuItem = true;
			optionText.changeX = false;
			optionText.targetY = i;
			optionText.alignment = CENTER;
			optionText.distancePerItem.y /= 1.2;

			if (!isSelectable) optionText.spawnPos.y -= 47;

			optionText.snapToPosition();
			grpOptions.add(optionText);

			if (isSelectable && curSelected == -1) curSelected = i;
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, 0x99000000);
		descBox.addPoint.set(-10, -10);
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 0, "", 32);
		descText.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		interpColor = new FlxInterpolateColor(bg.color);
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		if (!quitting) {
			if (sections.length > 1) {
				var shiftMult:Int = 1;
				if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upPressed:Bool = Controls.pressed('ui_up');
				var downJustPressed:Bool = Controls.justPressed('ui_down');
				var upJustPressed:Bool = Controls.justPressed('ui_up');
				if (upJustPressed || downJustPressed) {
					changeSelection(upJustPressed ? -shiftMult : shiftMult);
					holdTime = 0;
				}

				if (FlxG.mouse.wheel != 0) {
					FlxG.sound.play(Paths.sound('scrollMenu'), .2);
					changeSelection(-FlxG.mouse.wheel);
				}

				if (Controls.pressed('ui_down') || upPressed) {
					var checkLastHold:Int = Math.floor((holdTime - .5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - .5) * 10);

					if (holdTime > .5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (upPressed ? -shiftMult : shiftMult));
				}
			}

			interpColor.fpsLerpTo(Util.colorFromString(sections[curSelected][3]), .0625);
			bg.color = interpColor.color;

			if (Controls.justPressed('accept') && sections[curSelected][1] != null) {
				CreditSectionState.curCSection = sections[curSelected][1];
				CreditSectionState.cSectionisMod = #if MODS_ALLOWED modSectionsBound > 0 && curSelected >= modSectionsBound #else false #end;

				prevSelected = curSelected;
				FlxG.switchState(() -> new CreditSectionState());
				quitting = true;
			}

			if (Controls.justPressed('back')) {
				FlxG.sound.play(Paths.sound('cancelMenu'), .7);
				FlxG.switchState(() -> new MainMenuState());
				quitting = true;
			}
		}

		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected = FlxMath.wrap(curSelected + change, 0, sections.length - 1);
		} while (unselectableCheck(curSelected));

		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;
			if (!unselectableCheck(num)) item.alpha = (item.targetY == 0 ? 1 : .6);
		}

		descText.text = sections[curSelected][2];
		descText.gameCenter(X).y = FlxG.height - descText.height + offsetThing - 60;
		descText.updateHitbox();

		if (moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	#if MODS_ALLOWED
	static var modDescription:String = 'Credits Section for the mod "%s"';
	var modSectionsBound:Int = -1;

	var modCredits:Array<Array<String>> = [];
	function pushModCredits(?folder:String = null):Void {
		final modFolder:String = folder != null ? '$folder/' : '';
		var creditsFile:String = Paths.mods(modFolder + 'data/credits.txt');
		#if TRANSLATIONS_ALLOWED
		var translatedCredits:String = Paths.mods(modFolder + 'data/credits-${Settings.data.language}.txt');
		#end
		if (#if TRANSLATIONS_ALLOWED (FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end FileSystem.exists(creditsFile)) {
			var arr:Array<String> = File.getContent(creditsFile).split('\n');
			if (arr.length > 0) {
				var metadata:ModsMenuState.ModItem = new ModsMenuState.ModItem(folder);
				var name:String = metadata.name;
				var color:FlxColor = metadata.color;

				modCredits.push([name, folder, modDescription.replace('%s', name), color.toHexString(false, false)]);
			}
		}
	}
	#end

	inline function unselectableCheck(num:Int):Bool return sections[num].length <= 1;
}

class CreditSectionState extends MusicBeatState {
	public static var curCSection:String = 'psych';
	public static var cSectionisMod:Bool = false;
	
	var curSelected:Int = -1;
	var prevModDir:String;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var interpColor:FlxInterpolateColor;
	var descBox:AttachedSprite;

	final offsetThing:Float = -75;

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Credits"); #end
		prevModDir = Mods.currentModDirectory;
		persistentUpdate = true;

		initializeList();
		if (cSectionisMod) Mods.currentModDirectory = curCSection;

		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.antialiasing = Settings.data.antialiasing;
		add(bg);
		bg.gameCenter();

		add(grpOptions = new FlxTypedGroup<Alphabet>());

		for (i => credit in creditsStuff) {
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, credit[0], isSelectable ? NORMAL : BOLD);
			optionText.fieldWidth = FlxG.width;
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if (isSelectable) {
				if (credit[5] != null) Mods.currentModDirectory = credit[5];

				var str:String = 'credits/missing_icon';
				if (credit[1] != null && credit[1].length > 0) {
					var fileName:String = 'credits/icons/' + credit[1];
					if (Paths.fileExists('images/$fileName.png', IMAGE)) str = fileName;
					else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE)) str = fileName + '-pixel';
				}

				var icon:AttachedSprite = new AttachedSprite(str);
				if (str.endsWith('-pixel')) icon.antialiasing = false;
				icon.addPoint.x = optionText.width + 10;
				icon.sprTracker = optionText;

				// using a FlxGroup is too much fuss!
				add(icon);
				Mods.currentModDirectory = cSectionisMod ? curCSection : '';

				if (curSelected == -1) curSelected = i;
			} else optionText.alignment = CENTER;
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.addPoint.set(-10, -10);
		descBox.alphaMult = .6;
		descBox.alpha = .6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 0, "", 32);
		descText.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		interpColor = new FlxInterpolateColor(bg.color);
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		if (!quitting) {
			if (creditsStuff.length > 1) {
				var shiftMult:Int = 1;
				if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upPressed:Bool = Controls.pressed('ui_up');
				var downJustPressed:Bool = Controls.justPressed('ui_down');
				var upJustPressed:Bool = Controls.justPressed('ui_up');
				if (upJustPressed || downJustPressed) {
					changeSelection(upJustPressed ? -shiftMult : shiftMult);
					holdTime = 0;
				}

				if (FlxG.mouse.wheel != 0) {
					FlxG.sound.play(Paths.sound('scrollMenu'), .2);
					changeSelection(-shiftMult * FlxG.mouse.wheel);
				}

				if (Controls.pressed('ui_down') || upPressed) {
					var checkLastHold:Int = Math.floor((holdTime - .5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - .5) * 10);

					if (holdTime > .5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (upPressed ? -shiftMult : shiftMult));
				}
			}

			interpColor.fpsLerpTo(Util.colorFromString(creditsStuff[curSelected][4]), .0625);
			bg.color = interpColor.color;

			if (Controls.justPressed('accept') && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4))
				utils.WindowUtil.openURL(creditsStuff[curSelected][3]);

			if (Controls.justPressed('back')) {
				FlxG.sound.play(Paths.sound('cancelMenu'));

				var state:CreditsState = new CreditsState();
				state.curSelected = CreditsState.prevSelected;
				FlxG.switchState(() -> state);
				quitting = true;
			}
		}

		for (item in grpOptions.members) {
			if (item.type == BOLD) continue;
			var lerpVal:Float = Math.exp(-elapsed * 12);
			if (item.targetY == 0) {
				var lastX:Float = item.x;
				item.gameCenter(X);
				item.x = FlxMath.lerp(item.x - 70, lastX, lerpVal);
			} else item.x = FlxMath.lerp(200 + -40 * Math.abs(item.targetY), item.x, lerpVal);
		}
		super.update(elapsed);
	}

	override function destroy() {
		Mods.currentModDirectory = prevModDir;
		super.destroy();
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), .4);
		do {
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		} while (unselectableCheck(curSelected));

		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;
			if (!unselectableCheck(num)) {
				item.alpha = 0.6;
				if (item.targetY == 0) item.alpha = 1;
			}
		}

		descText.text = creditsStuff[curSelected][2];
		descText.updateHitbox();
		if (descText.text.trim().length > 0) {
			descText.visible = descBox.visible = true;
			descText.gameCenter(X).y = FlxG.height - descText.height + offsetThing - 60;

			if (moveTween != null) moveTween.cancel();
			moveTween = FlxTween.tween(descText, {y: descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();
		} else descText.visible = descBox.visible = false;
	}

	function initializeList() {
		#if MODS_ALLOWED if (cSectionisMod) initializeModList(curCSection); #end

		if (!cSectionisMod) {
			var dyn:Dynamic = Reflect.field(CreditsState, curCSection);
			var field:Array<Array<String>> = null;
			if (Std.isOfType(dyn, Array)) {
				field = cast dyn;
				if (field == null || field.length <= 0 || !Std.isOfType(field[0], Array) || !Std.isOfType(field[0][0], String)) field = null;
			}

			if (field == null || field.length <= 0) {
				switchToDefaultSection();
				field = cast Reflect.field(CreditsState, curCSection);
			}

			for (v in field) creditsStuff.push(v);
		}
	}

	#if MODS_ALLOWED
	function initializeModList(?folder:String = null) {
		var creditsFile:String = Paths.mods((folder != null ? '$folder/' : '') + 'data/credits.txt');
		#if TRANSLATIONS_ALLOWED
		var translatedCredits:String = Paths.mods((folder != null ? '$folder/' : '') + 'data/credits-${Settings.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED (FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end FileSystem.exists(creditsFile)) {
			for (i in File.getContent(creditsFile).split('\n')) {
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if (arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		} else return switchToDefaultSection();
		if (creditsStuff.length <= 0) return switchToDefaultSection();
	}
	#end

	function switchToDefaultSection() {
		curCSection = 'psych';
		cSectionisMod = false;
	}

	inline function unselectableCheck(num:Int):Bool return creditsStuff[num].length <= 1;
}