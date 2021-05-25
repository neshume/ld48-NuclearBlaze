package gm.en;

class FallingWreck extends Entity {
	public function new(xx:Float, yy:Float) {
		super(0,0);
		setPosPixel(xx,yy);
		pivotX = 0.5;
		pivotY = 0.5;
		wid = hei = 5;
		gravityMul = rnd(1.8, 2);
		collides = true;
		spr.setRandom(dict.fireWreck);
		sprScaleX = rnd(0.8,1,true);
		sprScaleY = rnd(0.8,1);
	}


	override function onLand(cHei:Float) {
		super.onLand(cHei);
		fx.wreckExplosion(attachX, attachY);
		dn.Bresenham.iterateDisc(cx,cy, 1, (x,y)->{
			if( sightCheck(x,y) )
				level.ignite(x,y, 2,1, true);
		});

		if( distCase(hero)<=0.8 )
			hero.hit(99,this);

		destroy();
	}

	override function postUpdate() {
		super.postUpdate();
		if( !cd.hasSetS("tail",0.03) ) {
			fx.wreckTail(centerX, centerY);
		}
	}
}