package gm.en;

class FxEmitter extends Entity {
	public var data : Entity_FxEmitter;
	var active : Bool;
	var bounds : h2d.col.Bounds;

	public function new(d:Entity_FxEmitter) {
		super(0,0);
		data = d;
		triggerId = data.f_triggerId;
		active = data.f_startActive;
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
	}

	override function trigger() {
		super.trigger();
		active = !active;
		triggerId = -1;
	}

	override function postUpdate() {
		super.postUpdate();

		if( active ) {
			switch data.f_type {
				case Drips:
					if( isOnScreenBounds() && !cd.hasSetS("fx", 0.2/data.f_customIntensity ) )
						fx.drips(wid==16 ? centerX+rnd(0,6,true) : rnd(left,right), top-2, data.f_customColor_int);

				case BlackSmoke:
					if( !cd.hasSetS("fx",0.06/data.f_customIntensity) ) {
						var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
						var x = 0.;
						var y = 0.;
						for(i in 0...n) {
							x = rnd(left,right);
							y = rnd(top,bottom);
							if( camera.isOnScreen(x,y,128) )
								fx.smoke(x, y, data.f_customColor_int, data.f_wind);
						}
					}

				case ColorSmoke:
					if( !cd.hasSetS("fx",0.06/data.f_customIntensity) ) {
						var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
						var x = 0.;
						var y = 0.;
						for(i in 0...n) {
							x = rnd(left,right);
							y = rnd(top,bottom);
							if( camera.isOnScreen(x,y,128) )
								fx.smoke(x, y, data.f_customColor_int, C.toBlack(data.f_customColor_int,0.5), data.f_wind);
						}
					}

				case Clouds:
					if( isOnScreenBounds(128) && !cd.hasSetS("fx",0.03/data.f_customIntensity) )
						for(i in 0...3)
							fx.cloud(rnd(left,right), rnd(top,bottom), data.f_customColor_int, data.f_dir);

				case SpeedLines:
					if( isOnScreenBounds(128) && !cd.hasSetS("fx",0.03/data.f_customIntensity) )
						for(i in 0...2)
							fx.speedLine(rnd(left,right), rnd(top,bottom), data.f_customColor_int, data.f_dir);

				case StarField:
					if( isOnScreenBounds(128) && !cd.hasSetS("fx",0.06/data.f_customIntensity) )
						fx.starField(rnd(left,right), rnd(top,bottom), data.f_customColor_int, data.f_dir);

				case RotorTop:
					if( isOnScreenBounds() && !cd.hasSetS("fx",0.2/data.f_customIntensity) )
						fx.helicopterRotorTop(centerX, top, data.f_dir, data.f_customColor_int);

				case RotorBack:
					if( isOnScreenBounds() && !cd.hasSetS("fx",0.1/data.f_customIntensity) )
						fx.helicopterRotorBack(centerX, centerY, data.f_dir, data.f_customColor_int);

				case Water:
					if( isOnScreenBounds() ) {
						if( !cd.hasSetS("bubbles",0.2/data.f_customIntensity) ) {
							var n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.33 );
							var x = 0.;
							var y = 0.;
							for(i in 0...n) {
								x = rnd(left,right);
								y = rnd(top,bottom);
								if( camera.isOnScreen(x,y,40) )
									fx.tinyBubbles(x,y, bounds, data.f_customColor_int);
							}

							n = M.ceil( M.round(wid/Const.GRID) * M.round(hei/Const.GRID) * 0.1 );
							for(i in 0...n)
								fx.largeBubbles(rnd(left,right), rnd(top,bottom), bounds, data.f_customColor_int);
						}

						if( !cd.hasSetS("surface",0.1/data.f_customIntensity) ) {
							for( x in cLeft+1...cRight )
								if( camera.isOnScreen(x*Const.GRID, top, 40) )
									fx.waterSurfaceRipples((x+rnd(0.3,0.7))*Const.GRID, top, data.f_customColor_int);

							for( x in cLeft+1...cRight-1 )
								if( camera.isOnScreen(x*Const.GRID, top, 40) )
									fx.waterSurfaceDark((x+rnd(0.3,0.7))*Const.GRID, top, data.f_customColor_int);

							if( camera.isOnScreen(left, top, 32) )
								fx.waterSideDrips(left,top, 1, data.f_customColor_int);
							if( camera.isOnScreen(right, top, 32) )
								fx.waterSideDrips(right,top, -1, data.f_customColor_int);
						}
					}
			}
		}
	}
}