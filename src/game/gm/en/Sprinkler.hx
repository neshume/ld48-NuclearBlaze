package gm.en;

class Sprinkler extends Entity {
	public static var ALL : Array<Sprinkler> = [];

	public var data : Entity_Sprinkler;
	var active : Bool;
	var oscillateCpt : Float;
	var ang : Float;

	public function new(d:Entity_Sprinkler) {
		super(0,0);
		ALL.push(this);
		data = d;
		triggerId = data.f_triggerId;
		revealFogOnTrigger = true;
		setPosPixel(data.pixelX, data.pixelY);
		ang = switch data.f_dir {
			case null,South: M.PIHALF;
			case North: -M.PIHALF;
			case East: 0;
			case West: M.PI;
		}
		gravityMul = 0;
		collides = false;
		active = data.f_startActive;
		oscillateCpt = rnd(0,100) * data.f_oscillation;
		pivotY = 0.5;


		spr.set( dict.sprinklerOff);
		spr.rotation = switch data.f_dir {
			case null, South: 0;
			case North: M.PI;
			case East: -M.PIHALF;
			case West: M.PIHALF;
		}
		game.scroller.add(spr,Const.DP_MAIN);
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
		if( active && isOnScreenCenter() && !cd.hasSetS("splash", 0.06) )
			fx.sprinkler(centerX+Math.cos(ang)*4, centerY+Math.sin(ang)*4);
	}

	public inline function isActive() return active;

	public function start() {
		active = true;
		fx.sprinklerStart(centerX, centerY, ang);
	}
	public function stop() {
		active = false;
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		if( active ) {
			for(oy in -1...2)
			for(ox in -1...2)
				level.decreaseFire(cx+ox, cy+oy, 0.5);
			if( !cd.hasSetS("bullet", 0.225) ) {
				final n = 3;
				for(i in 0...n) {
					var b = new gm.en.bu.WaterDrop(
						centerX+Math.cos(ang)*4,
						centerY+Math.sin(ang)*4,
						ang - 0.5*Math.sin(oscillateCpt)*data.f_oscillation - 0.15+0.3*Math.sin( M.PIHALF*(i/(n)) )
					);
					b.delayS( rnd(0,0.1) );
					b.power = 1.5;
					b.ignoreResist = true;
				}
				oscillateCpt += 0.45;
			}
		}
	}
}