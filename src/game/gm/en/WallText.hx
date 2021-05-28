package gm.en;

class WallText extends Entity {
	public function new(data:Entity_WallText) {
		super(0,0);
		setPosPixel(data.pixelX, data.pixelY);
		gravityMul = 0;
		collides = false;
		spr.set("empty");
		game.scroller.add(spr,Const.DP_BG);

		var tf = new h2d.Text(switch data.f_size {
			case Pixel: Assets.fontPixel;
			case Tiny: Assets.fontTiny;
			case Small: Assets.fontSmall;
			case Medium:  Assets.fontMedium;
			case Large: Assets.fontLarge;
		}, spr);
		tf.text = Lang.parseText( data.f_title );
		tf.textColor = data.f_color_int;
		tf.x = Std.int(-tf.textWidth*0.5);
		tf.y = Std.int(-tf.textHeight*0.5);

		switch data.f_style {
			case null:
			case Engraved:
				tf.filter = new h2d.filter.DropShadow(1, -M.PIHALF, 0x0,0.7, 0,1, true);
				tf.alpha = 0.75;

			case DropShadow:
				tf.filter = new h2d.filter.DropShadow(1, M.PIHALF, 0x0,0.7, 0,1, true);

			case Outline:
				tf.filter = new dn.heaps.filter.PixelOutline();

			case Keyboard:
				tf.font = Assets.fontPixel;
				tf.filter = new dn.heaps.filter.PixelOutline();
				var bg = new h2d.ScaleGrid( Assets.tiles.getTile(dict.keyboard), 3, 4 );
				spr.addChildAt(bg,0);
				bg.width = tf.textWidth + 8;
				bg.height = tf.textHeight + 2;
				bg.x = -Std.int(bg.width*0.5);
				bg.y = -Std.int(bg.height*0.5) + 2;

			case GamePad:
				tf.font = Assets.fontPixel;
				tf.filter = new dn.heaps.filter.PixelOutline();
				var bg = new h2d.ScaleGrid( Assets.tiles.getTile(dict.padButton), 8, 8 );
				spr.addChildAt(bg,0);
				bg.width = M.fmax( 16, tf.textWidth+8 );
				bg.height = 16;
				bg.x = -Std.int(bg.width*0.5);
				bg.y = -Std.int(bg.height*0.5) + 1;
				bg.color.setColor( C.addAlphaF(data.f_color_int) );
				tf.textColor = 0xffffff;
		}

		tf.alpha *= data.f_alpha;
	}

	override function dispose() {
		super.dispose();
	}

	override function postUpdate() {
		super.postUpdate();
	}
}