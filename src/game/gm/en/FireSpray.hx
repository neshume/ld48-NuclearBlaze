package gm.en;

class FireSpray extends Entity {
	public static var ALL : Array<FireSpray> = [];

	public var data : Entity_FireSpray;
	var active : Bool;
	public var ang : Float;

	public function new(d:Entity_FireSpray) {
		super(0,0);
		ALL.push(this);
		data = d;
		triggerId = data.f_id;
		revealFogOnTrigger = true;
		setPosPixel(data.pixelX, data.pixelY);
		gravityMul = 0;
		collides = false;
		active = data.f_startActive;
		ang = switch data.f_dir {
			case North: -M.PIHALF;
			case East: 0;
			case West: M.PI;
			case South: M.PIHALF;
		}

		spr.set("empty");
		game.scroller.add(spr,Const.DP_BG);
	}

	override function trigger() {
		super.trigger();
		if( active )
			stop();
		else
			start();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();

		if( isOnScreenCenter() )
			if( active && !cd.hasSetS("sprayFx",0.03) )
				fx.fireSpray(attachX, attachY, ang, data.f_distance*Const.GRID);
			else if( !active ) {
				if( !cd.hasSetS("sprayOffSmoke",0.15) )
					fx.fireSprayOffSmoke(attachX, attachY, ang, data.f_distance*Const.GRID);

				if( !cd.hasSetS("sprayOffSpark",0.3) )
					fx.fireSprayOffSparks(attachX, attachY, ang, data.f_distance*Const.GRID);
			}
	}

	public inline function isActive() return active;

	public function start() {
		active = true;
	}

	public function stop() {
		active = false;
		iterateOver( (d,x,y)->{
			var fs = level.getFireState(x,y);
			if( fs!=null ) {
				fs.resistance = 0;
				if( !level.hasMark(NearCollision, x,y) ) {
					fs.clear();
					fs.control(true, 999999);
				}
			}
			return true;
		});
	}


	function iterateOver( cb : (cDist:Int, fcx:Int, fcy:Int)->Bool ) {
		var fcx = cx;
		var fcy = cy;
		for(d in 0...Std.int(data.f_distance+1)) {
			if( !level.isValid(fcx,fcy) )
				break;

			if( !cb(d, fcx, fcy) )
				break;

			switch data.f_dir {
				case North: fcy--;
				case East: fcx++;
				case West: fcx--;
				case South: fcy++;
			}
		}
	}


	function applyEffect(cDist:Int, fcx:Int, fcy:Int) {
		// Hero damage
		if( hero.cx==fcx && hero.cy==fcy && hero.canBeHit() && !cd.hasSetS("hit",0.5) )
			hero.hit(1,this);

		// Ignition
		if( level.ignite(fcx, fcy, 2, 1) ) {
			var fs = level.getFireState(fcx,fcy);
			fs.resistance = 1;
			fs.strongFx = true;
			fs.propgationCdS = 0;
		}
		if( cDist>1 && !level.hasFireState(fcx,fcy) ) {
			var fs = level.getFireState(fcx,fcy,true);
			level.ignite(fcx,fcy,2);
			fs.propagates = false;
		}

		return true;
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		if( active ) {
			var d = distCase(hero);
			if( d<=6 )
				game.heat += (1-d/6)*0.1;

			iterateOver( applyEffect );
		}
	}
}