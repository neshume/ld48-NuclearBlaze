package gm.en;

class FireSpray extends Entity {
	public var data : Entity_FireSpray;
	public var active : Bool;
	public var ang : Float;

	public function new(d:Entity_FireSpray) {
		super(0,0);
		data = d;
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

	override function dispose() {
		super.dispose();
	}

	override function postUpdate() {
		super.postUpdate();

		if( active && !cd.hasSetS("sprayFx",0.03) )
			fx.fireSpray(attachX, attachY, ang, data.f_dist*Const.GRID);
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( active ) {
			var d = distCase(hero);
			if( d<=6 ) {
				game.heat += (1-d/6)*0.1;
			}
			var fcx = cx;
			var fcy = cy;
			for(d in 0...data.f_dist+1) {
				if( !level.isValid(fcx,fcy) )
					break;

				// Hero damage
				if( hero.cx==fcx && hero.cy==fcy && !hero.hasShield() && !cd.hasSetS("hit",0.5) )
					hero.hit(1,this);

				// Ignition
				if( level.ignite(fcx, fcy, 2, 1) ) {
					var fs = level.getFireState(fcx,fcy);
					fs.resistance = 1;
					fs.strongFx = true;
					fs.propgationCdS = 0;
				}
				if( d>1 && !level.hasFireState(fcx,fcy) ) {
					var fs = level.getFireState(fcx,fcy,true);
					level.ignite(fcx,fcy,2);
					fs.propagates = false;
				}

				switch data.f_dir {
					case North: fcy--;
					case East: fcx++;
					case West: fcx--;
					case South: fcy++;
				}
			}
		}
	}
}