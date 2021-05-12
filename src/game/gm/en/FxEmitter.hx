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

		if( active && isOnScreen() ) {
			switch data.f_type {
				case Drips:
					if( !cd.hasSetS("fx",0.1) )
						fx.drips(wid==16 ? 6 : rnd(left,right), top-2);

				case Smoke:
					if( !cd.hasSetS("fx",0.06) ) {
						var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
						for(i in 0...n)
							fx.smoke(rnd(left,right), rnd(top,bottom), data.f_customColor_int);
					}

				case Water:
					if( !cd.hasSetS("bubbles",0.2) ) {
						var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
						for(i in 0...n)
							fx.tinyBubbles(rnd(left,right), rnd(top,bottom), bounds, data.f_customColor_int);

						n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.1 );
						for(i in 0...n)
							fx.largeBubbles(rnd(left,right), rnd(top,bottom), bounds, data.f_customColor_int);
					}

					if( !cd.hasSetS("surface",0.1) ) {
						for( x in cLeft+1...cRight )
							fx.waterSurface((x+rnd(0.3,0.7))*Const.GRID, top, data.f_customColor_int);

						fx.waterSideDrips(left,top, 1, data.f_customColor_int);
						fx.waterSideDrips(right,top, -1, data.f_customColor_int);
					}
			}
		}
	}
}