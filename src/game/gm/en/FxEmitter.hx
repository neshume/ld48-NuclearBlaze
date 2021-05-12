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

		if( active && isOnScreenBounds() ) {
			switch data.f_type {
				case Drips:
					if( !cd.hasSetS("fx",0.1) )
						fx.drips(wid==16 ? 6 : rnd(left,right), top-2);

				case BlackSmoke:
					if( !cd.hasSetS("fx",0.06) ) {
						var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
						var x = 0.;
						var y = 0.;
						for(i in 0...n) {
							x = rnd(left,right);
							y = rnd(top,bottom);
							if( camera.isOnScreen(x,y,32) )
								fx.smoke(x, y, data.f_customColor_int);
						}
					}

				case ColorSmoke:
					if( !cd.hasSetS("fx",0.06) ) {
						var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
						var x = 0.;
						var y = 0.;
						for(i in 0...n) {
							x = rnd(left,right);
							y = rnd(top,bottom);
							if( camera.isOnScreen(x,y,32) )
								fx.smoke(x, y, data.f_customColor_int, C.toBlack(data.f_customColor_int,0.5));
						}
					}

				case Water:
					if( !cd.hasSetS("bubbles",0.2) ) {
						var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
						var x = 0.;
						var y = 0.;
						for(i in 0...n) {
							x = rnd(left,right);
							y = rnd(top,bottom);
							if( camera.isOnScreen(x,y,24) )
								fx.tinyBubbles(x,y, bounds, data.f_customColor_int);
						}

						n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.1 );
						for(i in 0...n)
							fx.largeBubbles(rnd(left,right), rnd(top,bottom), bounds, data.f_customColor_int);
					}

					if( !cd.hasSetS("surface",0.1) ) {
						for( x in cLeft+1...cRight )
							if( camera.isOnScreen(x*Const.GRID, top, 16) )
								fx.waterSurface((x+rnd(0.3,0.7))*Const.GRID, top, data.f_customColor_int);

						if( camera.isOnScreen(left, top, 16) )
							fx.waterSideDrips(left,top, 1, data.f_customColor_int);
						if( camera.isOnScreen(right, top, 16) )
							fx.waterSideDrips(right,top, -1, data.f_customColor_int);
					}
			}
		}
	}
}