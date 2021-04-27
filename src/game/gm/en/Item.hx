package gm.en;

class Item extends Entity {
	public var data : Entity_Item;
	public function new(d:Entity_Item) {
		data = d;
		super(d.cx, d.cy);

		gravityMul = 0.6;
		spr.set("item"+data.f_type.getName());
		spr.filter = new dn.heaps.filter.PixelOutline(0x0);
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( distCase(hero)<=1 && hero.isAlive() ) {
			fx.itemPickUp(centerX, centerY, Assets.worldData.getEnumColor(data.f_type) );
			hero.addItem(data.f_type);
			destroy();
			return;
		}

		if( onGround && !cd.hasSetS("jump",1) ) {
			blink(0xffcc00);
			dy = -0.3;
		}
	}
}