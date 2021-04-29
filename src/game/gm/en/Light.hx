package gm.en;

class Light extends Entity {
	var data : Entity_Light;
	var bulb : HSprite;
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

				largeHalo = Assets.tiles.h_get(dict.lightCircle,0, 0.5, 0.5);
				game.scroller.add(largeHalo, Const.DP_FX_FRONT);


			// case North:
			// case East:
			// case West:
			// case South:
			case _: // HACK
		}

		var dark = C.hexToInt("#6d50cd");

		bulb.colorize( C.toWhite(data.f_color_int,0.2) );

		core.colorize( data.f_color_int );
		core.blendMode = Add;
		core.smooth = true;

		mainHalo.setScale( data.f_radius*Const.GRID / ( mainHalo.tile.width*0.5 ) );
		mainHalo.colorize( C.interpolateInt(data.f_color_int, dark, 0.4) );
		mainHalo.blendMode = Add;
		mainHalo.smooth = true;

		largeHalo.setScale( 1.75*data.f_radius*Const.GRID / ( largeHalo.tile.width*0.5 ) );
		largeHalo.colorize( C.interpolateInt(data.f_color_int, dark, 0.66) );
		largeHalo.blendMode = Add;
		largeHalo.smooth = true;
	}

	override function dispose() {
		super.dispose();
		bulb.remove();
		core.remove();
		mainHalo.remove();
		largeHalo.remove();
	}

	override function postUpdate() {
		super.postUpdate();
		bulb.setPosition(attachX, attachY);
		core.setPosition(attachX, attachY);
		mainHalo.setPosition(attachX, attachY);
		largeHalo.setPosition(attachX, attachY);

		if( isOnScreen() && !cd.hasSetS("smoke",0.1) && power>=0.5 )
			fx.lightSmoke(centerX, centerY, data.f_color_int);

		if( isOnScreen() && !cd.hasSetS("flare",0.1) && power>=0.66 )
			fx.lightFlare(centerX, centerY, data.f_color_int);

		if( data.f_flicker ) {
			if( !cd.has("powered") && !cd.has("powerLock") ) {
				var t = rnd(3,7);
				cd.setS("powered", t);
				cd.setS("powerLock", t+rnd(2,4));
			}

			power += ( ( cd.has("powered") ? 0.7 : 0.2 ) - power ) * M.fmin(1, 0.3*tmod);
			if( !cd.has("flickerLock") ) {
				cd.setS("flickering", rnd(0.4,1));
				cd.setS("flickerLock", rnd(1,2));
			}
			if( cd.has("flickering") )
				power+=rnd(0, 0.1, true);
		}

		core.alpha = data.f_intensity * power;
		mainHalo.alpha = data.f_intensity*0.9 * power;
		largeHalo.alpha = data.f_intensity*0.5 * power;
	}
}