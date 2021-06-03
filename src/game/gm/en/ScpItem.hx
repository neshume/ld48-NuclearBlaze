package gm.en;

class ScpItem extends Entity {
	var data : Entity_ScpItem;

	public function new(d:Entity_ScpItem) {
		data = d;
		super(data.cx,data.cy);

		spr.set( dict.scpItem );
		game.scroller.add(spr, Const.DP_ENTITY_FRONT);
	}

	override function dispose() {
		super.dispose();
	}

	override function postUpdate() {
		super.postUpdate();
	}


	override function fixedUpdate() {
		super.fixedUpdate();
		if( !level.isBurning(cx,cy) )
			level.ignite(cx,cy,2,1, true);
		var fs = level.getFireState(cx,cy);
		fs.resistance = 1;
		fs.magic = true;
		fs.strongFx = true;
	}
}