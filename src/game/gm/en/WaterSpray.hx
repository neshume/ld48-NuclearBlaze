package gm.en;

class WaterSpray extends Entity {
	public static var ALL : Array<WaterSpray> = [];

	var recalled = false;
	var readyToSpray = false;
	var radius = 3;

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		gravityMul = 0.5;
		frict = 0.96;

		spr.set(dict.itemWaterSpray);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();
	}

	public function recall() {
		if( recalled )
			return;
		recalled = true;
		gravityMul = 0;
		collides = false;
	}

	override function onTouchWall(wallDir:Int) {
		super.onTouchWall(wallDir);

		if( dir==wallDir )
			dx*=-1;
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		// Come back to hero
		if( recalled && hero.isAlive() ) {
			var a = Math.atan2(hero.attachY-attachY, hero.attachX-attachX);
			var spd = 0.1;
			dx+=Math.cos(a)*spd;
			dy+=Math.sin(a)*spd;
			if( distCase(hero)<=1 ) {
				hero.addItem(WaterSpray);
				destroy();
			}
		}

		// Spray
		if( dy>=0 && readyToSpray ) {
			readyToSpray = false;
			fx.dotsExplosion(attachX, attachY, Const.WATER_COLOR);
			dn.Bresenham.iterateDisc(cx,cy, radius, (x,y)->{
				if( level.isBurning(x,y) ) {
					var fs = level.getFireState(x,y);
					fs.control();
					fs.decrease(1);
				}
				if( !level.hasWallCollision(x,y) )
					fx.fireSplash( (x+0.5)*Const.GRID, (y+0.5)*Const.GRID );
			});
		}

		if( !recalled ) {
			// Stop on fires
			if( level.getFireLevel(cx,cy)>=2 )
				dx*=0.85;

			// Bounce
			if( onGround && !cd.hasSetS("jump",0.4) ) {
				dx *= 0.65;
				dy = -0.2;
				readyToSpray = true;
			}
		}
	}
}