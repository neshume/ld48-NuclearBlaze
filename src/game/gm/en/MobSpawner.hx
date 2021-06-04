package gm.en;

class MobSpawner extends Entity {
	var data : Entity_Mob;

	public function new(d:Entity_Mob) {
		data = d;
		super(data.cx, data.cy);

		triggerId = data.f_spawnTriggerId;

		spr.set(dict.empty);
		gravityMul = 0;
		collides = false;
	}

	override function trigger() {
		super.trigger();
		gm.en.Mob.create(data);
		destroy();
	}

}