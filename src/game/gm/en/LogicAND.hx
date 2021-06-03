package gm.en;

class LogicAND extends Entity {
	public static var ALL : Array<LogicAND> = [];

	var data : Entity_LogicAND;
	var active = false;

	public function new(d:Entity_LogicAND) {
		data = d;

		super(0,0);

		ALL.push(this);
		setPosPixel(data.pixelX, data.pixelY);
		triggerId = data.f_receivedId;

		spr.set(dict.empty);
		gravityMul = 0;
		collides = false;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function trigger() {
		super.trigger();
		active = true;

		var ok = true;
		for(e in ALL)
			if( e.data.f_groupIdentifier==data.f_groupIdentifier && !e.active ) {
				ok = false;
				break;
			}
		if( ok ) {
			for(e in Entity.ALL)
				if( e.isAlive() && e.triggerId==data.f_outId )
					e.trigger();
			destroy();
		}
	}

	override function fixedUpdate() {
		super.fixedUpdate();
	}

}