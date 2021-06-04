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

		switch data.f_type {
			case Water:
				// Offset water surface
				setPosPixel(d.pixelX, d.pixelY + d.f_y);
				hei-=d.f_y;

			case _:
		}

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

				case Rain:
					if( !cd.hasSetS("fx", 0.06/data.f_customIntensity ) ) {
						var n = M.ceil( wid/Const.GRID*0.3 );
						for(i in 0...n) {
							var x = rnd(left,right);
							if( camera.isOnScreen(x,hero.centerY) )
								fx.rain(x, top-2, data.f_x, data.f_customColor_int);
						}
					}

				case GodRays:
					if( !cd.hasSetS("fx", 0.06/data.f_customIntensity ) ) {
						var n = M.ceil( wid/Const.GRID*0.2 );
						for(i in 0...n)
							fx.godRay(rnd(left,right), top, data.f_customColor_int);
					}

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

				case ComputerLights:
					if( isOnScreenBounds() && !cd.hasSetS("fx",0.3/data.f_customIntensity) )
						fx.computerLights(data.pixelX, data.pixelY, data.width, data.height, data.f_customColor_int);

				case GroundSparks:
					if( isOnScreenBounds() && !cd.hasSetS("fx",0.09/data.f_customIntensity) )
						fx.groundSparks(left, bottom, wid, data.f_customColor_int);

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

							if( hei>=Const.GRID )
								for( x in cLeft+1...cRight-1 )
									if( camera.isOnScreen(x*Const.GRID, top, 40) )
										fx.waterSurfaceDark((x+rnd(0.3,0.7))*Const.GRID, top, data.f_customColor_int);

							if( camera.isOnScreen(left, top, 32) )
								fx.waterSideDrips(left,top, 1, data.f_customColor_int);
							if( camera.isOnScreen(right, top, 32) )
								fx.waterSideDrips(right,top, -1, data.f_customColor_int);
						}

						// Hero splashes
						if( inBounds(hero.attachX, hero.attachY) ) {
							if( !cd.hasSetS("splash",0.06) ) {
								if( !cd.hasSetS("inWater",Const.INFINITE) )
									fx.enterWater(hero.attachX, top, data.f_customColor_int);
								fx.waterSplashes(hero.attachX, top, M.fabs(hero.dxTotal)>=0.1 ? 1 : 0.2, data.f_customColor_int);
							}
						}
						else {
							if( cd.has("inWater") )
								fx.leaveWater(hero.attachX, top, hero.dir, data.f_customColor_int);
							cd.unset("inWater");
						}
					}
			}
		}
	}
}