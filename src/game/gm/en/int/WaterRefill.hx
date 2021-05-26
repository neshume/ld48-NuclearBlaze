package gm.en.int;

class WaterRefill extends Entity {
	var data : Entity_WaterRefill;

	public function new(d:Entity_WaterRefill) {
		super(0,0);
		data = d;
		setPosPixel(d.pixelX, d.pixelY);
		setPivots(d.pivotX, d.pivotY);
		gravityMul = 0;
		collides = false;
		spr.set(dict.waterRefiller);
		Game.ME.scroller.add(spr, Const.DP_BG);
	}

	override function dispose() {
		super.dispose();
	}

	override function postUpdate() {
		super.postUpdate();

		if( isOnScreenCenter() ) {
			if( !cd.hasSetS("fx",0.09) )
				fx.waterRefiller(centerX, centerY+13);

			if( cd.has("used") ) {
				if( !cd.hasSetS("fxUse",0.03) )
					fx.waterRefillerUsed(centerX, centerY+13, hero.centerX, hero.centerY);

				if( !cd.hasSetS("fxPhong",0.25) )
					fx.waterRefillerPhong(centerX-1, centerY+3);
			}
		}

		if( hero.isAlive() && cd.has("used") && !cd.hasSetS("heroBlink",0.1) )
			hero.blink(0x2295ff);
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		if( !game.waterMaxed() && hero.isAlive() )
			if( M.iabs(hero.cx-cx)<=Const.db.WaterRefillRangeX && M.iabs(hero.cy-cy)<=Const.db.WaterRefillRangeY && sightCheck(hero) ) {
				game.refillWater(Const.db.WaterRefillRate);
				if( game.waterMaxed() && !hero.isWatering() && !cd.hasSetS("complete",0.8) )
					fx.waterRefillerComplete(hero.centerX, hero.centerY);
				cd.setS("used",0.1);
			}
	}
}