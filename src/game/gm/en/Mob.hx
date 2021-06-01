package gm.en;

class Mob extends Entity {
	public static var ALL : Array<Mob> = [];

	var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.mobs );
	var data : Entity_Mob;
	var prevAggro = false;

	var type(get,never) : Enum_MobType;
		inline function get_type() return data.f_type;

	private function new(d:Entity_Mob) {
		data = d;
		super(data.cx, data.cy);
		ALL.push(this);

		game.scroller.add(spr, Const.DP_MOB);
		spr.set(Assets.mobs);

		dir = data.f_dir==0 ? R.sign() : data.f_dir;
		if( data.f_lockAiOnCreate )
			lockAiS( rnd(0.8,1.5) );
	}


	public static function create(d:Entity_Mob) {
		return switch d.f_type {
			case Fly: new gm.en.mob.Fly(d);
			case Runner: new gm.en.mob.Runner(d);
		}
	}


	override function hit(dmg:Int, ?from:Entity) {
		if( hasShield() )
			return;

		super.hit(dmg, from);

		setShieldS(Const.db.ShieldOnHit);
		blink(0xffcc00);
	}

	public inline function hasShield() {
		return cd.has("shield");
	}

	function setShieldS(t:Float) {
		cd.setS("shield",t,false);
	}

	function aggro() {
		cd.setS("aggro", Const.db.DefaultAggroDuration, false);

		if( !prevAggro )
			onAggroStart();
		prevAggro = true;
	}

	function onAggroStart() {
		fx.aggro(this);
		hud.notify("start");
	}

	function onAggroEnd() {
		hud.notify("end");
	}

	inline function hasAggro() {
		return cd.has("aggro");
	}

	function lockAiS(t:Float) {
		cd.setS("aiLock",t,false);
	}

	public inline function aiLocked() {
		return cd.has("aiLock") || isChargingAction();
	}

	override function onDamage(dmg:Int, from:Entity) {
		super.onDamage(dmg, from);
		aggro();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function preUpdate() {
		super.preUpdate();
		if( !hasAggro() && prevAggro )
			onAggroEnd();
		prevAggro = hasAggro();
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( hero.isAlive() && distCase(hero)<=0.6 && !cd.hasSetS("heroHit",1) )
			hero.hit(1,this);
	}

}