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

	public function new(d:Entity_Trigger) {
		data = d;

		super(0,0);

		delayer = new dn.Delayer(Const.FPS);

		ALL.push(this);
		triggerId = data.f_triggerId;

		spr.set(dict.empty);
		gravityMul = 0;
		collides = false;

		game.scroller.add(spr, Const.DP_BG);
		switch data.f_type {
			case Gate:
				setPosPixel(data.pixelX, data.pixelY);
				spr.set(dict.pipeGate);
				pivotY = 0.5;

			case InvisibleArea:
				setPosPixel(data.pixelX, data.pixelY);
				pivotY = 0.5;

			case InvisibleGate:
				var top = data.cy;
				while( !level.hasAnyCollision(data.cx, top-1) )
					top--;
				var bottom = data.cy;
				while( !level.hasAnyCollision(data.cx, bottom+1) )
					bottom++;
				setPosCase(data.cx, top);
				xr = yr = 0;
				setPivots(0,0);
				hei = Const.GRID * (bottom-top+1);

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

	public static function getCurrent(by:Entity) : Null<Trigger> {
		if( !anyAvailable(by) )
			return null;

		var dh = new dn.DecisionHelper( ALL.filter( e->e.canBeManuallyTriggered(by) ) );
		dh.score( (e)->-e.distCase(by) );
		dh.score( (e)->by.dirTo(e)==by.dir ? 2 : 0 );
		return dh.getBest();
	}


	public function hold() {
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
		return data.f_type!=InvisibleGate && data.f_type!=InvisibleArea;
	}

	function execute() {
		done = true;
		g.visible = false;

		// Visual effect
		switch data.f_type {
			case Gate:
			case InvisibleGate, InvisibleArea:
			case TouchPlate:
				spr.set( dict.touchPlateOn );
				blink(0xffffff);
				setSquashY(0.5);
		}

		var eachDurationS = data.f_cinematicReveal ? 1.25  : !isVisibleTrigger() ? 0 : 0.5;
		var t = 0.;
		for(e in Entity.ALL) {

			// Trigger targets
			if( e.isAlive() && e.triggerId==triggerId && !e.is(gm.en.Trigger) ) {
				// Camera track
				if( data.f_cinematicReveal )
					delayer.addS( ()->{
						camera.clearCinematicTrackings();
						camera.cinematicTrack(e.centerX, e.centerY, eachDurationS);
					}, t);

				// Wire fx
				if( isVisibleTrigger() )
					delayer.addS( fx.triggerWire.bind(centerX, centerY, e.centerX, e.centerY, eachDurationS*0.2), t + eachDurationS*0.4 );

				// Trigger
				delayer.addS( e.trigger, t + eachDurationS*0.6 );

				// Trigger fx
				if( isVisibleTrigger() )
					delayer.addS( fx.triggerTarget.bind(e.centerX,e.centerY), t + eachDurationS*0.6 );

				// Fog
				if( e.revealFogOnTrigger )
					delayer.addS( level.revealFogArea.bind(e.cx, e.cy, 3), t + eachDurationS*0.2 );

				t+=eachDurationS;
			}
		}
		delayer.addS( camera.clearCinematicTrackings, t );

		switch data.f_type {
			case Gate:
				fx.dotsExplosion(centerX, centerY, data.f_fxColor_int);

			case TouchPlate:
				fx.touchPlate(centerX, bottom);

			case InvisibleArea:
			case InvisibleGate:
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

		if( !started && !done && isVisibleTrigger() && holdS<=0  && !cd.hasSetS("blink",0.5) )
			blink(data.f_fxColor_int);

		if( data.f_type==Gate )
			spr.setFrame( M.round( 9*holdS/data.f_gateHoldTime* spr.totalFrames() ) % (spr.totalFrames()) );
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

			if( data.f_type==InvisibleGate && hero.cx==cx && hero.cy>=cTop && hero.cy<=cBottom && sightCheck(hero) )
				start();
		}

		if( started && !done && !cd.has("executeLock") )
			execute();
	}
}