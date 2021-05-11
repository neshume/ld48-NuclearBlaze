package gm.en;

class FxEmitter extends Entity {
	public var data : Entity_FxEmitter;
	var active : Bool;

	public function new(d:Entity_FxEmitter) {
		super(0,0);
		data = d;
		triggerId = data.f_triggerId;
		active = triggerId<0;
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
		active = true;
	}

	override function postUpdate() {
		super.postUpdate();

		if( active && !cd.has("fx") && isOnScreen() ) {
			switch data.f_type {
				case Drips:
					fx.drips(centerX, attachY-2, wid==16 ? 6 : wid*0.5);
					cd.setS("fx",0.1);

				case Smoke:
					var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
					for(i in 0...n)
						fx.smoke(rnd(left,right), rnd(top,bottom), data.f_customColor_int);
					cd.setS("fx",0.06);
			}
		}
	}
}