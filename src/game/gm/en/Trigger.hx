package gm.en;

class Trigger extends Entity {
	public static var ALL : Array<Trigger> = [];

	public var useDistX = 1;
	public var useDistY = 1;
	var g : h2d.Graphics;
	var data : Entity_Trigger;
	var holdS = 0.;
	public var done = false;
	var started = false;
	var delayer : dn.Delayer;
	var consumedItem : Null<Enum_Items>;

	public function new(d:Entity_Trigger) {
		data = d;

		super(0,0);

		delayer = new dn.Delayer(Const.FPS);

		ALL.push(this);
		triggerId = data.f_triggerId;

		spr.set(dict.empty);
		gravityMul = 0;
		collides = false;
		consumedItem = data.f_consumedItem;

		game.scroller.add(spr, Const.DP_BG);
		switch data.f_type {
			case Valve:
				setPosPixel(data.pixelX, data.pixelY);
				if( consumedItem!=null )
					spr.set(dict.missingValve);
				else
					spr.set(dict.valve);
				pivotY = 0.5;

			case InvisibleArea:
				setPosPixel(data.pixelX, data.pixelY);
				pivotY = 0.5;

			case LevelComplete:
				setPosPixel(data.pixelX, data.pixelY);
				pivotY = 0.5;

			case InvisibleGate, IRGate:
				var top = data.cy;
				while( !level.hasAnyCollision(data.cx, top-1) )
					top--;
				var bottom = data.cy;
				while( !level.hasAnyCollision(data.cx, bottom+1) )
					bottom++;
				setPosCase(data.cx, top);
				hei = Const.GRID * (bottom-top+1);
				xr = yr = 0;
				setPivots(0,0);

				if( data.f_type==IRGate ) {
					spr.setCenterRatio(0.5,0);
					spr.set( dict.irGate );
				}


			case TouchPlate:
				setPosCase(data.cx, data.cy);
				spr.set(dict.touchPlateOff);

			case null:
		}

		g = new h2d.Graphics();
		game.scroller.add(g,Const.DP_UI);
		g.blendMode = Add;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);

		delayer.destroy();
		delayer = null;
	}

	public function canBeManuallyTriggered(by:Entity) {
		return
			isAlive() && !done && !started && by!=null && by.isAlive()
			&& data.f_type!=TouchPlate
			&& M.fabs(cx-by.cx)<=useDistX
			&& M.fabs(cy-by.cy)<=useDistY
			&& sightCheck(by);
	}

	public static function anyAvailable(by:Entity) : Bool {
		for(e in ALL )
			if( e.canBeManuallyTriggered(by) )
				return true;
		return false;
	}

	public static function getBest(by:Entity) : Null<Trigger> {
		if( !anyAvailable(by) )
			return null;

		var dh = new dn.DecisionHelper( ALL.filter( e->e.canBeManuallyTriggered(by) ) );
		dh.keepOnly( e->switch e.data.f_type {
			case Valve: true;
			case _: false;
		} );
		dh.score( (e)->-e.distCase(by) );
		dh.score( (e)->by.dirTo(e)==by.dir ? 2 : 0 );
		return dh.getBest();
	}


	public function hold() {
		if( consumedItem!=null ) {
			if( !hero.hasItem(consumedItem) ) {
				if( !cd.hasSetS("missingItem",1.5) )
					hero.sayBubble(Assets.tiles.getTile(dict.itemSpareValve), Assets.tilesDict.emoteQuestion, 0xaa0000);
				return;
			}
			else {
				hero.removeItem(consumedItem);
				fx.usedItem(centerX, centerY, 0xffcc00);
				shakeS(0.3);
				camera.bump(0,2);
				consumedItem = null;
				spr.set(dict.spareValve);
				hero.sayBubble(Assets.tiles.getTile(dict.itemSpareValve), Assets.tilesDict.emoteOk, 0x83c359);
			}
		}

		holdS+=1/Const.FIXED_UPDATE_FPS;
		cd.setS("maintain",0.1);
		if( holdS>=data.f_gateHoldTime) {
			holdS = data.f_gateHoldTime;
			start();
		}
		updateProgress();
	}


	function start() {
		started = true;
		if( data.f_triggerDelay<=0 )
			execute();
		else
			cd.setS("executeLock", data.f_triggerDelay);
	}

	public inline function isVisibleTrigger() {
		return switch data.f_type {
			case Valve: true;
			case TouchPlate: true;
			case IRGate: true;
			case InvisibleArea: false;
			case InvisibleGate: false;
			case LevelComplete: false;
		}
	}

	function isVisibleTriggerTarget(e:Entity) {
		if( data.f_silent )
			return false;

		if( e.is(gm.en.Repeater) || e.is(gm.en.CinematicEvent) || e.is(gm.en.LogicAND) || e.is(gm.en.WallText)  || e.is(gm.en.Explosive) )
			return false;

		return true;
	}

	function execute() {
		done = true;
		g.visible = false;

		// Visual effect
		switch data.f_type {
			case LevelComplete:
			case Valve:
			case IRGate:
			case InvisibleGate, InvisibleArea:
			case TouchPlate:
				spr.set( dict.touchPlateOn );
				blink(0xffffff);
				setSquashY(0.5);
		}

		var eachDurationS =
			data.f_silent ? 0 :
			data.f_cinematicReveal ? 1.25  :
			!isVisibleTrigger() || data.f_type==IRGate ? 0
			: 0.5;
		var t = 0.;
		for(e in Entity.ALL) {
			// Trigger targets
			if( e.isAlive() && e.triggerId==triggerId && !e.is(gm.en.Trigger) ) {
				// Camera track
				if( data.f_cinematicReveal && isVisibleTriggerTarget(e) )
					delayer.addS( ()->{
						camera.clearCinematicTrackings();
						camera.cinematicTrack(e.centerX, e.centerY, eachDurationS);
					}, t);

				// Wire fx
				if( isVisibleTrigger() && isVisibleTriggerTarget(e) )
					delayer.addS( fx.triggerWire.bind(centerX, centerY, e.centerX, e.centerY, eachDurationS*0.2), t + eachDurationS*0.4 );

				// Trigger
				delayer.addS( e.trigger, t + eachDurationS*0.6 );

				// Trigger fx
				if( isVisibleTrigger() && isVisibleTriggerTarget(e) )
					delayer.addS( fx.triggerTarget.bind(e.centerX,e.centerY), t + eachDurationS*0.6 );

				// Fog
				if( e.revealFogOnTrigger && isVisibleTriggerTarget(e) )
					delayer.addS( level.revealFogArea.bind(e.cx, e.cy, 3), t + eachDurationS*0.2 );

				t+=eachDurationS;
			}
		}
		// delayer.addS( camera.clearCinematicTrackings, t );

		switch data.f_type {
			case Valve:
				fx.dotsExplosion(centerX, centerY, data.f_fxColor_int);

			case IRGate:
				fx.irGateTrigger( Std.int(centerX)+1, top+3, Std.int(centerX)+1, bottom, 0xffdd00);
				fx.flashBangS(0xffcc00, 0.2, 0.8);

			case TouchPlate:
				fx.touchPlate(centerX, bottom);

			case InvisibleArea:
			case InvisibleGate:
			case LevelComplete:
		}
	}

	function updateProgress() {
		g.clear();
		g.beginFill(data.f_fxColor_int, 0.4);
		g.drawPieInner(0,0, 20,17, -M.PIHALF, M.PI2 * M.fclamp(holdS/data.f_gateHoldTime, 0, 1));
	}


	override function preUpdate() {
		super.preUpdate();
		delayer.update(tmod);
	}

	override function postUpdate() {
		super.postUpdate();

		g.setPosition(attachX, attachY);

		// Blink
		if( !started && !done && isVisibleTrigger() && data.f_type!=IRGate && holdS<=0  && !cd.hasSetS("blink",0.5) )
			blink(data.f_fxColor_int);

		switch data.f_type {
			case Valve:
				spr.setFrame( M.round( 9*holdS/data.f_gateHoldTime* spr.totalFrames() ) % (spr.totalFrames()) );

			case TouchPlate:
			case InvisibleArea:
			case InvisibleGate:
			case LevelComplete:

			case IRGate:
				spr.setPosition(centerX, top);
				if( !done && !cd.hasSetS("irFx",0.03) )
					fx.irGate( Std.int(centerX)+1, top+3, Std.int(centerX)+1, bottom, 0xff0000 );
		}
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		if( !done && !started ) {
			if( !cd.has("maintain") ) {
				holdS *= 0.8;
				if( holdS<=0.1 )
					holdS = 0;
				updateProgress();
			}

			if( data.f_type==TouchPlate && hero.cx==cx && hero.cy==cy && hero.onGround)
				start();

			if( data.f_type==InvisibleArea && distCase(hero)<=data.f_invisibleRadius )
				start();

			if( data.f_type==InvisibleGate && hero.cx==cx && hero.cy>=cTop && hero.cy<=cBottom )
				start();

			if( data.f_type==IRGate && hero.cx==cx && hero.cy>=cTop && hero.cy<=cBottom && sightCheck(hero) )
				start();

			if( data.f_type==LevelComplete && game.levelComplete() )
				start();
		}

		if( started && !done && !cd.has("executeLock") )
			execute();
	}
}