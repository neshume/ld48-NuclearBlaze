package gm.en;

class Trigger extends Entity {
	public static var ALL : Array<Trigger> = [];

	public var interactDist = 1;
	var g : h2d.Graphics;
	var data : Entity_Trigger;
	var holdS = 0.;
	public var holdTargetS = 2.;

	public function new(d:Entity_Trigger) {
		data = d;

		super(0,0);

		setPosPixel(data.pixelX, data.pixelY);
		ALL.push(this);
		pivotY = 0.5;

		spr.set("empty");
		gravityMul = 0;
		collides = false;

		g = new h2d.Graphics(spr);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public function canBeTriggered(by:Entity) {
		return isAlive() && by!=null && by.isAlive() && by.distCase(this)<=interactDist && sightCheck(by);
	}

	public static function anyAvailable(by:Entity) : Bool {
		for(e in ALL )
			if( e.canBeTriggered(by) )
				return true;
		return false;
	}
	public static function getCurrent(by:Entity) : Null<Trigger> {
		if( !anyAvailable(by) )
			return null;

		var dh = new dn.DecisionHelper( ALL.filter( e->e.canBeTriggered(by) ) );
		dh.score( (e)->-e.distCase(by) );
		dh.score( (e)->by.dirTo(e)==by.dir ? 2 : 0 );
		return dh.getBest();
	}


	public function hold() {
		holdS+=1/Const.FIXED_UPDATE_FPS;
		cd.setS("maintain",0.1);
		if( holdS>=holdTargetS ) {
			holdS = holdTargetS;
			onTrigger();
			destroy();
		}
		updateProgress();
	}

	function onTrigger() {
		for(e in gm.en.FireSpray.ALL)
			if( e.data.f_id==data.f_id )
				e.stop();

		fx.dotsExplosion(centerX, centerY, 0xffcc00);
	}

	function updateProgress() {
		g.clear();
		g.beginFill(0xffffff);
		g.drawPieInner(0,0, 8,6, -M.PIHALF, M.PI2 * M.fclamp(holdS/holdTargetS, 0, 1));
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !cd.has("maintain") ) {
			holdS *= 0.9;
			if( holdS<=0.1 )
				holdS = 0;
			updateProgress();
		}
	}
}