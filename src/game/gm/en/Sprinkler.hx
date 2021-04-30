package gm.en;

class Sprinkler extends Entity {
	public static var ALL : Array<Sprinkler> = [];

	public var data : Entity_Sprinkler;
	var active : Bool;
	var shootIdx : Int;

	public function new(d:Entity_Sprinkler) {
		super(0,0);
		ALL.push(this);
		data = d;
		triggerId = data.f_id;
		setPosPixel(data.pixelX, data.pixelY);
		gravityMul = 0;
		collides = false;
		active = data.f_startActive;
		shootIdx = irnd(0,100);


		spr.set( dict.sprinklerOff);
		game.scroller.add(spr,Const.DP_MAIN);
	}

	override function trigger() {
		super.trigger();
		start();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();
		if( active && isOnScreen() && !cd.hasSetS("splash", 0.06) )
			fx.wallSplash(centerX, centerY+3);
	}

	public inline function isActive() return active;

	public function start() {
		active = true;
	}
	public function stop() {
		active = false;
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		if( active ) {
			if( !cd.hasSetS("bullet", 0.1) ) {
				for(i in 0...2) {
					new gm.en.bu.WaterDrop( centerX, centerY+4, M.PIHALF - 0.5 * Math.cos(shootIdx*0.3 + i*0.7) );
				}
				shootIdx++;
			}
		}
	}
}