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
		tf.text = data.f_title;
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
				tf.filter = new h2d.filter.Glow(0x0,0.5, 2,2,2, true);
		}
	}

	override function dispose() {
		super.dispose();
	}

	override function postUpdate() {
		super.postUpdate();
	}
}