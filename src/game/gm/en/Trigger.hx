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
		triggerId = data.f_id;

		spr.set("empty");
		gravityMul = 0;
		collides = false;

		game.scroller.add(spr, Const.DP_BG);
		switch data.f_type {
			case Gate:
				setPosPixel(data.pixelX, data.pixelY);
				spr.set(dict.pipeGate);
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
		if( holdS>=data.f_holdTime) {
			holdS = data.f_holdTime;
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
			case TouchPlate:
				spr.set( dict.touchPlateOn );
				blink(0xffffff);
				setSquashY(0.5);
		}

		// Triggering sequence
		var t = 0.35;
		var lastT = t;
		for(e in Entity.ALL)
			if( e.isAlive() && e.triggerId==triggerId ) {
				if( e.distCase(hero)>=5 && data.f_cameraReveal ) {
					delayer.addS(camera.trackEntity.bind(e,false), t);
					delayer.addS(e.trigger, t+0.7);
					lastT = t;
					t+=1;
				}
				else {
					delayer.addS(e.trigger, t);
					lastT = t;
					t+=0.4;
				}
			}

		delayer.addS(camera.trackEntity.bind(hero,false), t);
		hero.dx*=0.4;
		if( data.f_cameraReveal )
			hero.lockControlsS(lastT+0.1);
		level.suspendFireForS(t+0.5);

		switch data.f_type {
			case Gate:
				fx.dotsExplosion(centerX, centerY, data.f_fxColor_int);

			case TouchPlate:
				fx.touchPlate(centerX, bottom);
		}
	}

	function updateProgress() {
		g.clear();
		g.beginFill(data.f_fxColor_int, 0.4);
		g.drawPieInner(0,0, 20,17, -M.PIHALF, M.PI2 * M.fclamp(holdS/data.f_holdTime, 0, 1));
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
			spr.setFrame( M.round( 9*holdS/data.f_holdTime* spr.totalFrames() ) % (spr.totalFrames()) );
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !done && !cd.has("maintain") ) {
			holdS *= 0.8;
			if( holdS<=0.1 )
				holdS = 0;
			updateProgress();
		}

		if( !done && data.f_type==TouchPlate && hero.cx==cx && hero.cy==cy && hero.onGround) {
			execute();
		}

	}
}