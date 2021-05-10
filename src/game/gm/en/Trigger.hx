package gm.en;

class Trigger extends Entity {
	public static var ALL : Array<Trigger> = [];

	public var useDistX = 1;
	public var useDistY = 1;
	var g : h2d.Graphics;
	var data : Entity_Trigger;
	var holdS = 0.;
	public var done = false;
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

			case Invisible:
				setPosPixel(data.pixelX, data.pixelY);
				pivotY = 0.5;

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

	public function canBeTriggered(by:Entity) {
		return
			isAlive() && !done && by!=null && by.isAlive()
			&& data.f_type!=TouchPlate
			&& M.fabs(cx-by.cx)<=useDistX
			&& M.fabs(cy-by.cy)<=useDistY
			&& sightCheck(by);
	}

	public static function anyAvailable(by:Entity) : Bool {
		for(e in ALL )
			if( e.canBeTriggered(by) )
				return true;
		return false;
	}

	public static function getCurrent(by:Entity) : Null<Trigger> {
		if( !anyAvailable(by) )
			return null;

		var dh = new dn.DecisionHelper( ALL.filter( e->e.canBeTriggered(by) ) );
		dh.score( (e)->-e.distCase(by) );
		dh.score( (e)->by.dirTo(e)==by.dir ? 2 : 0 );
		return dh.getBest();
	}


	public function hold() {
		holdS+=1/Const.FIXED_UPDATE_FPS;
		cd.setS("maintain",0.1);
		if( holdS>=data.f_gateHoldTime) {
			holdS = data.f_gateHoldTime;
			execute();
		}
		updateProgress();
	}

	function execute() {
		done = true;
		g.visible = false;

		// Visual effect
		switch data.f_type {
			case Gate:
			case Invisible:
			case TouchPlate:
				spr.set( dict.touchPlateOn );
				blink(0xffffff);
				setSquashY(0.5);
		}

		var t = data.f_type==Invisible ? 0 : 0.4;
		for(e in Entity.ALL)
			if( e.isAlive() && e.triggerId==triggerId && !e.is(gm.en.Trigger) ) {
				var durationS = hero.distCase(e)>=10 ? 1.4 : 0.4;
				if( data.f_type==Invisible )
					durationS = 0.2;

				if( data.f_cinematicReveal )
					camera.cinematicTrack(e.centerX, e.centerY, durationS);

				if( data.f_type!=Invisible )
					delayer.addS(fx.triggerWire.bind(centerX, centerY, e.centerX, e.centerY, 0.3), t-0.3);
				delayer.addS(e.trigger, t);
				level.revealFogArea(e.cx, e.cy, 2);
				t+=durationS;
			}

		switch data.f_type {
			case Gate:
				fx.dotsExplosion(centerX, centerY, data.f_fxColor_int);

			case TouchPlate:
				fx.touchPlate(centerX, bottom);

			case Invisible:
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

		if( !done && holdS<=0  && !cd.hasSetS("blink",0.5) )
			blink(data.f_fxColor_int);

		if( data.f_type==Gate )
			spr.setFrame( M.round( 9*holdS/data.f_gateHoldTime* spr.totalFrames() ) % (spr.totalFrames()) );
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !done && !cd.has("maintain") ) {
			holdS *= 0.8;
			if( holdS<=0.1 )
				holdS = 0;
			updateProgress();
		}

		if( !done && data.f_type==TouchPlate && hero.cx==cx && hero.cy==cy && hero.onGround)
			execute();

		if( !done && data.f_type==Invisible && distCase(hero)<=data.f_invisibleRadius )
			execute();
	}
}