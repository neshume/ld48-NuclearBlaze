package gm.en;

class Mob extends Entity {
	public static var ALL : Array<Mob> = [];

	var data : Entity_Mob;

	var type(get,never) : Enum_MobType;
		inline function get_type() return data.f_type;

	private function new(d:Entity_Mob) {
		data = d;
		super(data.cx, data.cy);
		ALL.push(this);
		dir = data.f_dir;
		if( data.f_lockAiOnCreate )
			lockAiS( rnd(0.8,1.5) );
	}


	public static function create(d:Entity_Mob) {
		return switch d.f_type {
			case Jumper: new gm.en.mob.Jumper(d);
		}
	}


	override function hit(dmg:Int, ?from:Entity) {
		if( hasShield() )
			return;

		super.hit(dmg, from);

		setShieldS(0.3);
		blink(0xffcc00);
	}

	public inline function hasShield() {
		return cd.has("shield");
	}

	function setShieldS(t:Float) {
		cd.setS("shield",t,false);
	}

	function lockAiS(t:Float) {
		cd.setS("aiLock",t,false);
	}

	public inline function aiLocked() {
		return cd.has("aiLock");
	}

	override function onDamage(dmg:Int, from:Entity) {
		super.onDamage(dmg, from);

	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( hero.isAlive() && distCase(hero)<=0.6 && !cd.hasSetS("heroHit",1) )
			hero.hit(1,this);
	}

}