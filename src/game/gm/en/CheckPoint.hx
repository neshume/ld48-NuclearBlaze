package gm.en;

class CheckPoint extends Entity {
	public var data : Entity_CheckPoint;

	public function new(d:Entity_CheckPoint) {
		data = d;
		super(data.cx, data.cy);
		setPosPixel(data.pixelX, data.pixelY);
		gravityMul = 0;
		pivotY = 0.5;
		collides = false;
		spr.set(dict.empty);
	}

	override function trigger() {
		super.trigger();
		game.registerCheckPoint(data);
		destroy();
	}

	override function fixedUpdate() {
		super.fixedUpdate();
		if( hero.isAlive() && distCase(hero)<=data.f_radius && ( !data.f_requireSight || sightCheck(hero) ) )
			trigger();
	}
}