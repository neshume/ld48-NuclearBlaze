package gm.en.mob;

class Jumper extends gm.en.Mob {
	public function new(d:Entity_Mob) {
		super(d);
		frictX = 0.98;
		frictY = 0.92;
		gravityMul*=0.5;
		initLife( Std.int(Const.db.JumperHP) );
		spr.set(dict.testMob);
	}

	override function onDamage(dmg:Int, from:Entity) {
		super.onDamage(dmg, from);
		bump(-dirTo(hero)*0.05, -0.1);
	}

	override function onDie() {
		super.onDie();
		fx.mobDeath(centerX, centerY);
	}

	override function lockAiS(t:Float) {
		super.lockAiS(t);
		cancelAction();
	}

	override function onTouchWall(wallDir:Int) {
		super.onTouchWall(wallDir);
		dir = -wallDir;
		dx *= -1;
	}

	override function onLand(cHei:Float) {
		super.onLand(cHei);
		dx*=0.4;
		fx.mediumLand(attachX, attachY, 0.5);
		if( cHei>=1 )
			setSquashY(0.5);
	}

	override function postUpdate() {
		super.postUpdate();
		if( !cd.hasSetS("fxTail",0.03) )
			fx.tail(this, 0xff0000);
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( onGround )
			dx*=0.7;

		if( !aiLocked() ) {
			if( onGround && level.hasAnyCollision(cx+dir,cy) )
				dir*=-1;

			if( onGround && !isChargingAction() && !cd.hasSetS("jump",1) )
				chargeAction("jump", 0.5, ()->{
					cancelVelocities();
					dx = dir*0.2;
					dy = -0.4;
					setSquashX(0.5);
				});
		}
	}

}