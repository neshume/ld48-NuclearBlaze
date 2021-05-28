package gm.en;

class CameraOffset extends Entity {
	public static var ALL : Array<CameraOffset> = [];

	public var data : Entity_CameraOffset;

	public function new(d:Entity_CameraOffset) {
		super(0,0);
		ALL.push(this);
		data = d;
		setPosPixel(d.pixelX, d.pixelY);
		pivotX = 0;
		pivotY = 0;
		wid = d.width;
		hei = d.height;
		gravityMul = 0;
		collides = false;
		spr.set("empty");
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public inline function isActive() return isAlive() && cd.has("active");

	override function fixedUpdate() {
		super.fixedUpdate();

		if( hero.isAlive() && hero.attachX>=left && hero.attachY>=top && hero.attachX<=right && hero.attachY<=bottom ) {
			camera.cd.setS("hasOffset", 0.2);
			cd.setS("active", 0.1);
		}
	}
}