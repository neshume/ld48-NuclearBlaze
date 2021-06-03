package gm.en;

class RoofFire extends Entity {
	public var data : Entity_RoofFire;

	public function new(d:Entity_RoofFire, subCx:Int) {
		data = d;

		super(subCx, data.cy);

		triggerId = data.f_triggerId;
		gravityMul = 0;
		collides = false;
		spr.set("empty");

		yr = 0;
		pivotX = data.pivotX;
		pivotY = data.pivotY;
		wid = Const.GRID;
		hei = Const.GRID*5; // Makes "isOnScreenBounds" work better

		var fs = level.getFireState(cx,cy, true);
		fs.resistance = data.f_resistance;

		if( triggerId<0 )
			trigger();
	}


	override function trigger() {
		super.trigger();
		level.ignite(cx,cy,2,1, true);
		cd.setS("tick", rnd(1,6), true);
	}

	override function postUpdate() {
		super.postUpdate();

		if( isOnScreenBounds() ) {
			if( !level.isBurning(cx,cy) && !cd.hasSetS("dustFx", rnd(1,2)) )
				fx.blackDust( (cx+rnd(0,1))*Const.GRID, top);

			if( !level.isBurning(cx,cy) && !cd.hasSetS("emberFx", rnd(1,2)) )
				fx.ember( (cx+rnd(0,1))*Const.GRID, top+rnd(0,0.5)*Const.GRID );

			if( !cd.hasSetS("dirtFx", rnd(1,5)) )
				fx.blackDirt( (cx+rnd(0,1))*Const.GRID, top);
		}

		if( cd.has("announcing") && !cd.hasSetS("announceFx",0.06) )
			fx.wreckAnnounce( (cx+0.5)*Const.GRID, top, 1-cd.getRatio("announcing"));

	}

	override function fixedUpdate() {
		super.fixedUpdate();

			if( !cd.hasSetS("tick",rnd(5,8)) && level.isBurning(cx,cy) && !level.getFireState(cx,cy).isUnderControl() ) {
				cd.setS("ready", Const.INFINITE);
				cd.setS("announcing", 1.1);
			}

			if( cd.has("ready") && !cd.has("announcing") ) {
				new gm.en.FallingWreck( (cx+rnd(0.4,0.6))*Const.GRID, top );
				cd.unset("ready");
			}
	}
}