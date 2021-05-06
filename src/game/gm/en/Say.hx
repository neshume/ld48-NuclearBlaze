package gm.en;

class Say extends Entity {
	var data : Entity_Say;

	public function new(d:Entity_Say) {
		super(0,0);
		data = d;
		triggerId = data.f_triggerId;
		setPosPixel(d.pixelX, d.pixelY);
		gravityMul = 0;
		collides = false;
		spr.set("empty");
	}

	override function dispose() {
		super.dispose();
	}

	override function trigger() {
		super.trigger();

		if( game.polite && data.f_politeText!=null )
			hero.say(data.f_politeText, data.f_color_int);
		else
			hero.say(data.f_text, data.f_color_int);
		game.addSlowMo("say",1, 0.8);
		destroy();
}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( hero.isAlive() && distCase(hero)<=data.f_triggerDist && ( !data.f_needSight || sightCheck(hero) ) )
			trigger();
	}
}