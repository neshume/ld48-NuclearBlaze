package gm.en;

class WaterSpray extends Entity {
	public static var ALL : Array<WaterSpray> = [];

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		gravityMul = 0;
		collides = false;

		spr.set(dict.itemWaterSpray);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();

		spr.y += Math.cos(ftime*0.1 + uid)*2;
	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}
}