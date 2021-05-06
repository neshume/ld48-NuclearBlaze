package gm.en;

class FogPiercer extends Entity {
	public var data : Entity_FogPiercer;

	public function new(d:Entity_FogPiercer) {
		super(0,0);
		data = d;
		triggerId = data.f_triggerId;
		setPosPixel(d.pixelX, d.pixelY);
		pivotX = 0;
		pivotY = 0;
		wid = d.width;
		hei = d.height;
		gravityMul = 0;
		collides = false;
		spr.set("empty");

		if( triggerId<0 )
			trigger();
	}

	override function trigger() {
		super.trigger();
		for( y in cy...cy+M.round(hei/Const.GRID) )
		for( x in cx...cx+M.round(wid/Const.GRID) )
			level.revealFog(x,y);
	}
}