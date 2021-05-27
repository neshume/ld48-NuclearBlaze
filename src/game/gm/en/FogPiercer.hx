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

		if( triggerId<0 && !data.f_selfTriggerOnTouch )
			trigger();
	}

	override function trigger() {
		super.trigger();

		for( y in cTop...cBottom )
		for( x in cLeft...cRight )
			level.revealFog(x,y, data.f_triggerId<0 && !data.f_selfTriggerOnTouch);

		destroy();
	}

	override function fixedUpdate() {
		super.fixedUpdate();
		if( data.f_selfTriggerOnTouch && hero.cx>=cLeft && hero.cx<=cRight && hero.cy>=cTop && hero.cy<=cBottom )
			trigger();
	}
}