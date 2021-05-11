package gm.en;

class FxEmitter extends Entity {
	public var data : Entity_FxEmitter;
	var active : Bool;
	var bounds : h2d.col.Bounds;

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

		bounds = new h2d.col.Bounds();
		bounds.xMin = left;
		bounds.xMax = right;
		bounds.yMin = top;
		bounds.yMax = bottom;

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
					fx.drips(wid==16 ? 6 : rnd(left,right), top-2);
					cd.setS("fx",0.1);

				case Smoke:
					var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
					for(i in 0...n)
						fx.smoke(rnd(left,right), rnd(top,bottom), data.f_customColor_int);
					cd.setS("fx",0.06);

				case Water:
					var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
					for(i in 0...n)
						fx.bubbles(rnd(left,right), rnd(top,bottom), bounds, data.f_customColor_int);

					n = M.ceil( wid/Const.GRID * 0.7 );
					for(i in 0...n)
						fx.waterSurface(rnd(left+6,right-6), top, data.f_customColor_int);

					fx.waterSideDrips(left,top, 1, data.f_customColor_int);
					fx.waterSideDrips(right,top, -1, data.f_customColor_int);
					cd.setS("fx",0.12);
			}
		}
	}
}