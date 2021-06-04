package gm;

import dn.Process;

class Game extends Process {
	public static var ME : Game;

	public var app(get,never) : App; inline function get_app() return App.ME;

	/** Game controller (pad or keyboard) **/
	public var ca : dn.heaps.Controller.ControllerAccess;

	/** Particles **/
	public var fx : Fx;

	/** Basic viewport control **/
	public var camera : Camera;

	/** Container of all visual game objects. Ths wrapper is moved around by Camera. **/
	public var scroller : h2d.Layers;

	/** Level data **/
	public var level : Level;

	/** UI **/
	public var hud : ui.Hud;

	/** Slow mo internal values**/
	var curGameSpeed = 1.0;
	var slowMos : Map<String, { id:String, t:Float, f:Float }> = new Map();


	public var hero : Hero;
	public var curLevelId(get,never) : String;
		inline function get_curLevelId() return level.data.identifier;

	public var kidMode = false;
	public var polite(get,never) : Bool;
		inline function get_polite() return kidMode;

	public var heat : Float = 0.;
	var fadeMask : h2d.Bitmap;
	var heatMask : h2d.Bitmap;
	var coldMask : h2d.Bitmap;

	var upgrades : Map<Enum_Items, Bool> = [];
	public var water = 0.;
	var validatedCheckPoints : Array<LPoint> = [];


	public function new() {
		super(App.ME);

		ME = this;
		ca = App.ME.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(App.ME.root, Const.DP_ENTITY_MAIN);

		scroller = new h2d.Layers();
		root.add(scroller, Const.DP_ENTITY_MAIN);

		scroller.filter = new h2d.filter.Nothing(); // force rendering for pixel perfect

		fx = new Fx();
		hud = new ui.Hud();
		camera = new Camera();

		// Fade in/out mask
		fadeMask = new h2d.Bitmap( h2d.Tile.fromColor( C.hexToInt("#000000") ) );
		root.add(fadeMask, Const.DP_TOP);
		fadeMask.visible = false;

		// Heat/cold masks
		heatMask = new h2d.Bitmap( h2d.Tile.fromColor( C.hexToInt("#ff6600") ) );
		root.add(heatMask, Const.DP_FX_FRONT);
		heatMask.alpha = 0;

		coldMask = new h2d.Bitmap( h2d.Tile.fromColor( C.hexToInt("#1f567f") ) );
		root.add(coldMask, Const.DP_FX_FRONT);
		coldMask.blendMode = Add;
		coldMask.alpha = 0;

		// Start level
		var levelData = Assets.worldData.all_levels.Main_menu;
		#if debug
		for(l in Assets.worldData.levels)
			if( l.l_Entities.all_DebugStartPoint.length>0 ) {
				levelData = l;
				break;
			}
		#end
		refillWater();
		startLevel(levelData);


		#if debug
		Console.ME.enableStats();
		var tf : h2d.Text = null;
		Console.ME.stats.addComponent( (f)->{
			if( tf==null )
				tf = new h2d.Text(Assets.fontSmall, f);
			tf.text = Std.string( @:privateAccess fx.pool.count() + " fx" );
		});
		#end
	}


	public function fadeFromBlack(speed=1.0) {
		fadeMask.visible = true;
		tw.terminateWithoutCallbacks(fadeMask.alpha);
		tw.createS(fadeMask.alpha, 1>0, 1.2/speed).end( ()->fadeMask.visible = false );
	}

	public function fadeToBlack( ?cb:Void->Void ) {
		fadeMask.visible = true;
		tw.terminateWithoutCallbacks(fadeMask.alpha);
		tw.createS(fadeMask.alpha, 0>1, 0.5);

		delayer.cancelById("fade");
		if( cb!=null )
			delayer.addS("fade", cb, 0.5);
	}

	public inline function hasWater() {
		return water>0;
	}

	public inline function waterMaxed() {
		return water>=getMaxWater();
	}

	public inline function getMaxWater() {
		return 1.0;
	}

	public inline function useWater(v:Float) {
		if( !hasWater() ) {
			if( !cd.hasSetS("shakeDepleted",0.25) )
				hud.shakeWater(true);
			return false;
		}
		else {
			if( hasUpgrade(UpWaterTank) )
				v*=0.5;
			water = M.fmax(water-v, 0);
			hud.setWater(water);
			hud.shakeWater();
			return true;
		}
	}

	public inline function setWater(v:Float) {
		water = M.fclamp(v, 0, getMaxWater());
		hud.setWater(water);
	}

	public inline function refillWater(v=9999.) {
		water = M.fmin(water+v, getMaxWater());
		hud.setWater(water);
		if( water<1 ) {
			hud.blinkWater(0x2ad5ff);
			hud.shakeWater();
		}
	}

	public inline function unlockUpgrade(i:Enum_Items) {
		upgrades.set(i,true);
		hud.setUpgrades(upgrades);
		switch i {
			case Key:
			case GreenCard:
			case BlueCard:
			case WaterSpray:
			case SpareValve:
			case UpWaterLadder:
			case UpWaterUp:
			case UpShield:
			case UpWaterTank:
				refillWater();

			case UpDodge:
		}
	}

	inline function relockUpgrade(i:Enum_Items) {
		upgrades.remove(i);
		hud.setUpgrades(upgrades);
	}

	public inline function hasUpgrade(i:Enum_Items) {
		return upgrades.exists(i);
	}

	public function restartCurrentLevel() {
		refillWater();
		startLevel( level.data );
	}

	public function nextLevel() {
		var idx = Lib.getArrayIndex(level.data, Assets.worldData.levels);
		if( idx >= Assets.worldData.levels.length-1 ) {
			hud.notify(L.t._("Looped back at the beginning"));
			idx = 0;
		}
		else
			idx++;
		level.destroy();
		validatedCheckPoints = [];
		startLevel( Assets.worldData.levels[idx] );
	}


	public static inline function exists() {
		return ME!=null && !ME.destroyed;
	}


	/** Load a level **/
	public function startLevel(l:World.World_Level) {
		// Cleanup
		if( level!=null )
			level.destroy();
		fx.clear();
		for(e in Entity.ALL) // <---- Replace this with more adapted entity destruction (eg. keep the player alive)
			e.destroy();
		garbageCollectEntities();
		hud.clear();
		camera.reset();
		ui.Document.closeAny();

		// Inits
		heat = 0;
		delayer.cancelById("deathMsg");
		cd.unset("successMsg");

		// Save
		if( !l.f_isGameMenu ) {
			app.save.state.levelId = l.identifier;
			app.save.state.upgrades = {
				var all = [];
				for(u in upgrades.keys())
					all.push( u.getName() );
				all;
			}
			app.save.save();
		}


		// Start
		level = new Level(l);
		hero = new gm.en.Hero();
		camera.clampToLevelBounds = level.data.f_clampCameraToBounds;

		// Debug start equipment & settings
		#if debug
		if( level.data.l_Entities.all_DebugStartPoint.length>0 ) {
			var d = level.data.l_Entities.all_DebugStartPoint[0];
			hero.setShield(d.f_shieldDurationS);
			hero.forceFastFall(d.f_initialFastFall);
			setWater(d.f_water);
			for(i in d.f_startInv)
				if( gm.en.Item.isUpgradeItem(i) )
					unlockUpgrade(i);
				else
					hero.addItem(i);
			if( d.f_unlockAllUpgrades )
				for(k in Enum_Items.getConstructors()) {
					var i = Enum_Items.createByName(k);
					if( gm.en.Item.isUpgradeItem(i) )
						unlockUpgrade(i);
				}
		}
		#end

		// Remove upgrades found in this level
		for(e in l.l_Entities.all_Item)
			if( gm.en.Item.isUpgradeItem(e.f_type) )
				relockUpgrade(e.f_type);

		for(d in level.data.l_Entities.all_Door) new gm.en.int.Door(d);
		for(d in level.data.l_Entities.all_HorizontalDoor) new gm.en.int.HorizontalDoor(d);
		for(d in level.data.l_Entities.all_Item) new gm.en.Item(d);
		for(d in level.data.l_Entities.all_Dialog) new gm.en.Dialog(d);
		for(d in level.data.l_Entities.all_Tutorial) new gm.en.Tutorial(d);
		for(d in level.data.l_Entities.all_Exit) new gm.en.Exit(d);
		for(d in level.data.l_Entities.all_WallText) new gm.en.WallText(d);
		for(d in level.data.l_Entities.all_CameraOffset) new gm.en.CameraOffset(d);
		for(d in level.data.l_Entities.all_FireSpray) new gm.en.FireSpray(d);
		for(d in level.data.l_Entities.all_Trigger) new gm.en.Trigger(d);
		for(d in level.data.l_Entities.all_Repeater) new gm.en.Repeater(d);
		for(d in level.data.l_Entities.all_LogicAND) new gm.en.LogicAND(d);
		for(d in level.data.l_Entities.all_Light) new gm.en.Light(d);
		for(d in level.data.l_Entities.all_Sprinkler) new gm.en.Sprinkler(d);
		for(d in level.data.l_Entities.all_Explosive) new gm.en.Explosive(d);
		for(d in level.data.l_Entities.all_FogPiercer) new gm.en.FogPiercer(d);
		for(d in level.data.l_Entities.all_FxEmitter) new gm.en.FxEmitter(d);
		for(d in level.data.l_Entities.all_FireStarter) new gm.en.FireStarter(d);
		for(d in level.data.l_Entities.all_CheckPoint) new gm.en.CheckPoint(d);
		for(d in level.data.l_Entities.all_CinematicEvent) new gm.en.CinematicEvent(d);
		for(d in level.data.l_Entities.all_BreakableGround) new gm.en.int.BreakableGround(d);
		for(d in level.data.l_Entities.all_WaterRefill) new gm.en.int.WaterRefill(d);
		for(d in level.data.l_Entities.all_Document) new gm.en.int.DocumentItem(d);
		for(d in level.data.l_Entities.all_Ally) new gm.en.Ally(d);
		for(d in level.data.l_Entities.all_ScpItem) new gm.en.ScpItem(d);

		for(d in level.data.l_Entities.all_Mob) {
			if( d.f_triggerId<0 )
				gm.en.Mob.create(d);
			else
				new gm.en.MobSpawner(d);
		}

		for(d in level.data.l_Entities.all_RoofFire) {
			for( cx in d.cx...d.cx+M.round(d.width/Const.GRID) )
				new gm.en.RoofFire(d, cx);
		}

		if( !level.data.f_fog )
			for( cy in 0...level.cHei)
			for( cx in 0...level.cWid)
				level.revealFog(cx,cy, true);

		for(d in level.data.l_Entities.all_Smoker)
			dn.Bresenham.iterateDisc(d.cx, d.cy, d.f_radius, (x,y)->{
				if( level.hasFireState(x,y) ) {
					var fs = level.getFireState(x,y);
					fs.extinguished = true;
					fs.smokePower = d.f_intensity;
					fs.smokeColor = d.f_smokeColor_int;
				}
			});

		for(d in level.data.l_Entities.all_FixedFire) {
			var fs = level.getFireState(d.cx, d.cy, true);
			fs.ignite(FireState.MAX, 1);
			fs.resistance = d.f_resistance;
			fs.strongFx = true;
		}


		if( level.data.f_isGameMenu )
			new GameMenu();


		// for(d in level.data.l_Entities.all_FireStarter)
		// 	dn.Bresenham.iterateDisc( d.cx, d.cy, d.f_range, (x,y)->{
		// 		level.ignite(x,y, d.f_startFireLevel);
		// 		var fs = level.getFireState(x,y);
		// 		if( fs!=null )
		// 			fs.resistance = d.f_resistance;
		// 	});

		camera.centerOnTarget();
		hud.onLevelStart();
		Process.resizeAll();
		fadeFromBlack(level.data.f_fadeInSpeed);
	}


	public function registerCheckPoint(data:Entity_CheckPoint) {
		for(pt in validatedCheckPoints)
			if( pt.cx==data.cx && pt.cy==data.cy )
				return false;
		validatedCheckPoints.push( LPoint.fromCase(data.cx, data.cy) );
		return true;
	}

	public function getHeroStartPosition() : { pt:LPoint, initialFastFall:Float, dir:Int }{
		// Base start pos
		var h = level.data.l_Entities.all_Hero[0];
		var pos = {
			pt: LPoint.fromCase(h.cx, h.cy),
			initialFastFall: h.f_initialFastFall,
			dir: h.f_lookRight ? 1 : -1,
		}

		// Debug start
		#if debug
		var debug = level.data.l_Entities.all_DebugStartPoint[0];
		if( debug!=null )
			pos.pt.setLevelCase(debug.cx, debug.cy);
		#end

		// Checkpoints
		if( validatedCheckPoints.length>0 ) {
			var last = validatedCheckPoints[validatedCheckPoints.length-1];
			for(c in level.data.l_Entities.all_CheckPoint)
				if( c.cx==last.cx && c.cy==last.cy ) {
					pos.pt.setLevelCase(c.cx, c.cy);
					pos.initialFastFall = c.f_initialFastFall;
					break;
				}
		}

		return pos;
	}


	/** Called when either CastleDB or `const.json` changes on disk **/
	@:allow(assets.Assets)
	function onDbReload() {
		hud.notify("DB reloaded");
	}


	/** Called when LDtk file changes on disk **/
	@:allow(assets.Assets)
	function onLdtkReload() {
		hud.notify("LDtk reloaded");
		if( level!=null )
			startLevel( Assets.worldData.getLevel(level.data.uid) );
	}

	/** Window/app resize event **/
	override function onResize() {
		super.onResize();
		fadeMask.scaleX = w();
		fadeMask.scaleY = h();

		heatMask.scaleX = w();
		heatMask.scaleY = h();

		coldMask.scaleX = w();
		coldMask.scaleY = h();
	}


	/** Garbage collect any Entity marked for destruction. This is normally done at the end of the frame, but you can call it manually if you want to make sure marked entities are disposed right away, and removed from lists. **/
	public function garbageCollectEntities() {
		if( Entity.GC==null || Entity.GC.length==0 )
			return;

		for(e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	/** Called if game is destroyed, but only at the end of the frame **/
	override function onDispose() {
		super.onDispose();

		fx.destroy();
		for(e in Entity.ALL)
			e.destroy();
		garbageCollectEntities();
	}


	/**
		Start a cumulative slow-motion effect that will affect `tmod` value in this Process
		and all its children.

		@param sec Realtime second duration of this slowmo
		@param speedFactor Cumulative multiplier to the Process `tmod`
	**/
	public function addSlowMo(id:String, sec:Float, speedFactor=0.3) {
		if( slowMos.exists(id) ) {
			var s = slowMos.get(id);
			s.f = speedFactor;
			s.t = M.fmax(s.t, sec);
		}
		else
			slowMos.set(id, { id:id, t:sec, f:speedFactor });
	}


	/** The loop that updates slow-mos **/
	final function updateSlowMos() {
		// Timeout active slow-mos
		for(s in slowMos) {
			s.t -= utmod * 1/Const.FPS;
			if( s.t<=0 )
				slowMos.remove(s.id);
		}

		// Update game speed
		var targetGameSpeed = 1.0;
		for(s in slowMos)
			targetGameSpeed*=s.f;
		curGameSpeed += (targetGameSpeed-curGameSpeed) * (targetGameSpeed>curGameSpeed ? 0.2 : 0.6);

		if( M.fabs(curGameSpeed-targetGameSpeed)<=0.001 )
			curGameSpeed = targetGameSpeed;
	}


	/**
		Pause briefly the game for 1 frame: very useful for impactful moments,
		like when hitting an opponent in Street Fighter ;)
	**/
	public inline function stopFrame() {
		ucd.setS("stopFrame", 0.2);
	}


	/** Loop that happens at the beginning of the frame **/
	override function preUpdate() {
		super.preUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.preUpdate();
	}

	/** Loop that happens at the end of the frame **/
	override function postUpdate() {
		super.postUpdate();

		// Update slow-motions
		updateSlowMos();
		baseTimeMul = ( 0.2 + 0.8*curGameSpeed ) * ( ucd.has("stopFrame") ? 0.3 : 1 );
		Assets.tiles.tmod = tmod;

		// Entities post-updates
		for(e in Entity.ALL) if( !e.destroyed ) e.postUpdate();

		// Entities final updates
		for(e in Entity.ALL) if( !e.destroyed ) e.finalUpdate();

		// Dispose entities marked as "destroyed"
		garbageCollectEntities();


		// Heat management
		if( !kidMode && !cd.hasSetS("heatCheck",0.1) ) {
			// Detect heat surrounding hero
			var fireLevels = 0.;
			if( hero.isAlive() ) {
				var r = 7;
				dn.Bresenham.iterateDisc(hero.cx, hero.cy, r, (x,y)->{
					if( level.isBurning(x,y) ) {
						fireLevels += level.getFireLevel(x,y) * ( !hero.sightCheck(x,y) ? 0.6 : 1 ) * ( 0.4+0.6*( 1 - hero.distCase(x,y) / r ) );
					}
				});
			}
			else
				fireLevels = 999;

			if( fireLevels>0 ) {
				var targetHeat = M.fclamp( fireLevels/6, 0, 1 );
				if( targetHeat>heat )
					heat += ( targetHeat-heat ) * M.fmin(1, 0.15*tmod);
			}
		}

		// Apply heat
		if( level.fireCount==0 ) {
			heat = M.fclamp(heat, 0, 1);
			heat *= Math.pow(0.980,tmod);
		}
		else {
			heat = M.fclamp(heat, 0.45, 1);
			heat *= Math.pow(0.997,tmod);
		}
		heatMask.alpha = 0.5*heat;
		coldMask.alpha = ( level.fireCount>0 ? 0.2 : 0.5 ) * (1-heat);
	}


	/** Main loop but limited to 30 fps (so it might not be called during some frames) **/
	override function fixedUpdate() {
		super.fixedUpdate();

		// Entities "30 fps" loop
		for(e in Entity.ALL) if( !e.destroyed ) e.fixedUpdate();
	}

	public function levelComplete() {
		return level.fireCount==0 && successTimerS>=0.3 || level.data.f_ignoreFires;
	}


	public function setScreenshotMode(active:Bool) {
		if( active ) {
			scroller.add(hero.spr, Const.DP_FX_FRONT);
			cd.setS("screenshot", Const.INFINITE);
			hud.clearNotifications();
			for(e in Entity.ALL) {
				e.disableDebugBounds();
				e.debug();
			}
			for(e in gm.en.Tutorial.ALL)
				e.dispose();
			Console.ME.disableStats();
			hero.clearBlink();
			hero.postUpdate();
		}
		else {
			cd.unset("screenshot");
			scroller.add(hero.spr, Const.DP_ENTITY_MAIN);
		}
	}


	/** Main loop **/
	var successTimerS = 0.;
	override function update() {
		super.update();

		// Entities main loop
		for(e in Entity.ALL) if( !e.destroyed ) e.update();

		// Victory
		if( level.fireCount==0 ) {
			successTimerS+=1/Const.FPS * tmod;
			if( successTimerS>=0.3 && !cd.hasSetS("successMsg",Const.INFINITE) && !level.data.f_disableCompleteAnnounce )
				hero.say(L.t._("Clear! Proceeding deeper..."), 0xccff00);
		}
		else
			successTimerS = 0;

		// Water warning
		if( !hasWater() && !cd.hasSetS("waterBlink",0.5) )
			hud.blinkWater(0xff0000,0.1);

		// if( water<=0.33 && !cd.hasSetS("waterBlink",0.5) )
		// 	if( !hasWater() )
		// 		hud.blinkWater(0xff0000,0.1);
		// 	else
		// 		hud.blinkWater(0x328acd);


		// Global key shortcuts
		if( !App.ME.anyInputHasFocus() && !ui.Modal.hasAny() && !ca.locked() ) {

			// Exit by pressing ESC twice
			#if hl
			if( ca.isKeyboardPressed(K.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					hud.notify(Lang.t._("Press ESCAPE again to exit."));
				else {
					#if debug
					App.ME.exit();
					#else
					App.ME.mainMenu();
					#end
				}
			#end

			// Attach debug drone (CTRL-SHIFT-D)
			#if debug
			if( ca.isKeyboardPressed(K.D) && ca.isKeyboardDown(K.CTRL) && ca.isKeyboardDown(K.SHIFT) )
				new DebugDrone(); // <-- HERE: provide an Entity as argument to attach Drone near it

			// Next level
			if( ca.isKeyboardPressed(K.N) )
				nextLevel();

			// Fog
			if( ca.isKeyboardPressed(K.F) )
				level.fogRender.visible = !level.fogRender.visible;

			// Clear save
			if( ca.isKeyboardDown(K.SHIFT) && ca.isKeyboardPressed(K.S) ) {
				app.save.clear();
				hud.notify("Cleared save");
			}

			// Kill all mobs
			if( ca.isKeyboardPressed(K.K) ) {
				for(e in gm.en.Mob.ALL) e.hit(9999,hero);
			}

			// Clear all
			if( ca.isKeyboardPressed(K.C) ) {
				for(e in gm.en.FireSpray.ALL) e.stop();
				for(e in gm.en.Sprinkler.ALL) e.start();

				for(cy in 0...level.cHei)
				for(cx in 0...level.cWid)
					if( level.isBurning(cx,cy) )
						level.getFireState(cx,cy).clear();
			}
			#end

			// Restart
			if( ca.isKeyboardPressed(K.R) && ca.isKeyboardDown(K.SHIFT) )
				App.ME.mainMenu();
			else if( ca.selectPressed() )
				restartCurrentLevel();

		}
	}
}

