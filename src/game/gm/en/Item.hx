package gm.en;

class Item extends Entity {
	public var data : Entity_Item;
	var halo : Null<HSprite>;
	public var isUpgrade(default,null) = false;

	public function new(d:Entity_Item) {
		data = d;
		super(d.cx, d.cy);

		isUpgrade = isUpgradeItem(data.f_type);
		wid = hei = isUpgrade ? 11 : 13;
		gravityMul = 0.6;
		spr.set("item"+data.f_type.getName());
		spr.filter = new dn.heaps.filter.PixelOutline(0x0);

		if( isUpgrade ) {
			halo = Assets.tiles.h_get(dict.upHalo,0, 0.5, 0.5);
			game.scroller.add(halo, Const.DP_FX_BG);
			halo.setPosition(sprX,sprY);
		}
	}

	public static function isUpgradeItem(k:Enum_Items) {
		return switch k {
			case Key, GreenCard, BlueCard: false;
			case WaterSpray: true;
			case UpWaterLadder: true;
			case UpWaterUp: true;
			case UpShield: true;
			case UpWaterTank: true;
			case UpDodge: true;
		}
	}

	override function dispose() {
		super.dispose();

		if( halo!=null ) {
			halo.remove();
			halo = null;
		}
	}


	override function postUpdate() {
		super.postUpdate();

		if( halo!=null ) {
			halo.x += ( sprX - halo.x ) * 0.3;
			halo.y += ( Std.int( sprY - spr.tile.height*0.5 ) - halo.y ) * 0.3;
		}

		if( isUpgrade && !cd.hasSetS("fx",0.03) && isOnScreenCenter() )
			fx.upgradeHalo(centerX, centerY);
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		// Pick up
		if( distCase(hero)<=1 && hero.isAlive() ) {
			fx.itemPickUp(centerX, centerY, Assets.worldData.getEnumColor(data.f_type) );
			if( isUpgrade ) {
				hud.upgradeFound(data.f_type);
				game.unlockUpgrade(data.f_type);
				fx.flashBangS(0xffcc00, 0.3, 1);
			}
			else {
				fx.flashBangS(0x0088ff, 0.2, 0.4);
				hero.addItem(data.f_type);
			}
			destroy();
			return;
		}

		// Halo anim
		if( halo!=null && !cd.hasSetS("shine",1) )
			halo.anim.play(dict.upHalo).setSpeed(0.3);

		// Jump
		if( !isUpgrade && onGround && !cd.hasSetS("jump",1) ) {
			blink(0xffcc00);
			dy = -0.22;
		}
	}
}