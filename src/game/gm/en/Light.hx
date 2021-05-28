package gm.en;

class Light extends Entity {
	var data : Entity_Light;
	var bulb : HSprite;
	var white : Null<HSprite>;
	var core : HSprite;
	var mainHalo : HSprite;
	var largeHalo : HSprite;
	var power = 1.0;

	public function new(data:Entity_Light) {
		super(0,0);
		this.data = data;
		setPosPixel(data.pixelX, data.pixelY);
		gravityMul = 0;
		collides = false;
		triggerId = data.f_triggerId;
		entityVisible = data.f_startActive;

		wid = data.width;
		hei = data.height;

		spr.set(dict.empty);
		game.scroller.add(spr,Const.DP_FX_BG);

		switch data.f_spotDir {
			case null:
				pivotY = 0.5;

				bulb = Assets.tiles.h_get(dict.lightCircleBulb,0, 0.5, 0.5);
				game.scroller.add(bulb, Const.DP_BG);

				core = Assets.tiles.h_get(dict.lightCircleCore,0, 0.5, 0.5);
				game.scroller.add(core, Const.DP_FX_FRONT);
				core.setScale(0.5);

				mainHalo = Assets.tiles.h_get(dict.lightCircle,0, 0.5, 0.5);
				game.scroller.add(mainHalo, Const.DP_FX_FRONT);
				mainHalo.setScale( data.f_radius*Const.GRID / ( mainHalo.tile.width*0.5 ) );

				largeHalo = Assets.tiles.h_get(dict.lightCircle,0, 0.5, 0.5);
				game.scroller.add(largeHalo, Const.DP_FX_FRONT);


			case North, East, West, South:
				bulb = Assets.tiles.h_get(dict.lightSpotBulb,0, 0.5, 0);
				game.scroller.add(bulb, Const.DP_BG);

				white = Assets.tiles.h_get(dict.lightSpotWhite,0, 0.5, 0);
				game.scroller.add(white, Const.DP_BG);
				white.colorize( C.toWhite(data.f_color_int, 0.8) );

				core = Assets.tiles.h_get(dict.lightSpotCore,0, 0.5, 0);
				game.scroller.add(core, Const.DP_FX_FRONT);
				core.setScale(data.f_radius*Const.GRID / ( core.tile.width*0.5 ));

				mainHalo = Assets.tiles.h_get(dict.lightSpot,0, 0.5, 0);
				game.scroller.add(mainHalo, Const.DP_FX_FRONT);
				mainHalo.setScale( data.f_radius*Const.GRID / ( mainHalo.tile.width*0.3 ) );

				largeHalo = Assets.tiles.h_get(dict.lightCircle,0, 0.5, 0.5);
				game.scroller.add(largeHalo, Const.DP_FX_FRONT);

				switch data.f_spotDir {
					case North:
						pivotY = 1;
						yr = 1.2;
						white.rotation = bulb.rotation = core.rotation = mainHalo.rotation = M.PI;

					case East:
						pivotX = 0;
						pivotY = 0.5;
						xr = -0.2;
						white.rotation = bulb.rotation = core.rotation = mainHalo.rotation = -M.PIHALF;

					case West:
						pivotX = 1;
						pivotY = 0.5;
						xr = 1.2;
						white.rotation = bulb.rotation = core.rotation = mainHalo.rotation = M.PIHALF;

					case South:
						pivotY = 0;
						yr = 0;

					case null:
				}
		}

		var dark = C.hexToInt("#6d50cd");

		bulb.colorize( C.toWhite(data.f_color_int,0.2) );

		core.colorize( data.f_color_int );
		core.blendMode = Add;
		core.smooth = true;

		mainHalo.colorize( C.interpolateInt(data.f_color_int, dark, 0.4) );
		mainHalo.blendMode = Add;
		mainHalo.smooth = true;

		largeHalo.setScale( 1.75*data.f_radius*Const.GRID / ( largeHalo.tile.width*0.5 ) );
		largeHalo.colorize( C.interpolateInt(data.f_color_int, dark, 0.66) );
		largeHalo.blendMode = Add;
		largeHalo.smooth = true;
	}

	override function trigger() {
		super.trigger();
		entityVisible = !entityVisible;
	}

	override function dispose() {
		super.dispose();
		if( white!=null )
			white.remove();
		bulb.remove();
		core.remove();
		mainHalo.remove();
		largeHalo.remove();
	}

	public inline function isSpot() return data.f_spotDir!=null;
	public inline function getSpotAng() : Float {
		return switch data.f_spotDir {
			case null: 0;
			case North: -M.PIHALF;
			case East: 0;
			case West: M.PI;
			case South: M.PIHALF;
		}
	}

	override function postUpdate() {
		super.postUpdate();

		bulb.visible = !data.f_hideSprite && entityVisible;
		bulb.setPosition(attachX, attachY);

		core.setPosition(attachX, attachY);
		if( white!=null )
			white.setPosition(attachX, attachY);
		core.visible = !data.f_hideSprite && entityVisible;

		mainHalo.setPosition(attachX, attachY);
		mainHalo.visible = entityVisible;

		largeHalo.setPosition(attachX, attachY);
		largeHalo.visible = entityVisible;

		if( white!=null )
			white.visible = entityVisible;

		if( isOnScreenCenter() && entityVisible ) {
			if( !data.f_hideSprite && !cd.hasSetS("smoke",0.1) && power>=0.5 )
				fx.lightSmoke(centerX, centerY, data.f_color_int);

			if( !data.f_hideSprite && !isSpot() && !cd.hasSetS("flare",0.1) && power>=0.66 )
				fx.lightFlare(centerX, centerY, data.f_color_int, data.f_intensity);
		}

		if( data.f_flicker ) {
			if( !cd.has("powered") && !cd.has("powerLock") ) {
				// Turn ON
				var t = rnd(3,7);
				cd.setS("powered", t);
				cd.setS("powerLock", t+rnd(2,4));
			}

			power += ( ( cd.has("powered") ? 0.7 : 0.2 ) - power ) * M.fmin(1, 0.3*tmod);
			if( !cd.has("flickerLock") ) {
				cd.setS("flickering", rnd(0.3,0.6));
				cd.setS("flickerLock", rnd(0.9,1.2));
			}
			if( cd.has("flickering") )
				power+=rnd(0, 0.2, true);
		}

		if( data.f_gyro )
			power = 0.6 + 0.4*Math.cos(ftime*0.2);

		core.alpha = data.f_intensity * power;
		if( white!=null )
			white.alpha = power;
		mainHalo.alpha = data.f_intensity*0.9 * power;
		largeHalo.alpha = data.f_intensity*0.5 * power;
	}
}