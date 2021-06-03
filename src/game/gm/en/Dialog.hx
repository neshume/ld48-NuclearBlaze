package gm.en;

class Dialog extends Entity {
	var data : Entity_Dialog;
	var lines : Array<String>;

	var started = false;

	public function new(d:Entity_Dialog) {
		super(0,0);
		data = d;
		lines = data.f_lines.map( raw->Lang.parseText(raw) );
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
		if( !started ) {
			started = true;
			if( data.f_startDelay>0 )
				cd.setS("nextLine", data.f_startDelay);

		}
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( !started && hero.isAlive() && distCase(hero)<=data.f_selfTriggerDist && ( !data.f_needSight || sightCheck(hero) ) )
			trigger();

		if( started && !cd.has("nextLine") ) {
			var line = lines.shift();

			// Detect parameters
			var color : Null<Int> = null;
			var radio = false;
			var announce = false;
			if( line.indexOf(">")>0 ) {
				var params = line.split(">")[0].toLowerCase();
				line = line.split(">")[1];
				radio = params.indexOf("r")>=0;
				announce = params.indexOf("a")>=0;
				if( params.indexOf("+")>=0 )
					color = 0xd6f264;
				if( params.indexOf("!")>=0 )
					color = 0xdf3e23;
			}

			// Polite variations
			if( line.indexOf("|")>=0 )
				line = StringTools.trim( line.split("|")[ game.polite ? 1 : 0] );
			var durationS = radio ? hud.radio(line, color) : announce ? hud.announcement(line,color) : hero.say(line, color);
			durationS*=0.75;
			game.addSlowMo("say",1, 0.8);
			if( lines.length==0 )
				destroy();
			else
				cd.setS("nextLine",durationS);
		}
	}
}