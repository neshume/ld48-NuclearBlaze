package gm.en;

class Repeater extends Entity {
	var data : Entity_Repeater;

	public function new(d:Entity_Repeater) {
		data = d;

		super(0,0);
		setPosPixel(data.pixelX, data.pixelY);
		triggerId = data.f_receivedId;

		spr.set(dict.empty);
		gravityMul = 0;
		collides = false;
	}

	override function trigger() {
		super.trigger();
		if( data.f_delay<=0 )
			repeat();
		else {
			cd.setS("triggered",Const.INFINITE);
			cd.setS("repeatLock",data.f_delay);
		}
	}

	function repeat() {
		for(e in Entity.ALL)
			if( e.isAlive() && e.triggerId==data.f_followId )
				e.trigger();

		destroy();
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( cd.has("triggered") && !cd.has("repeatLock") )
			repeat();
	}

}