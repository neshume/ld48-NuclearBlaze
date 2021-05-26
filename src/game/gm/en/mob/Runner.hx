package gm.en.mob;

class Runner extends gm.en.Mob {
	public function new(d:Entity_Mob) {
		super(d);
		frictX = 0.98;
		frictY = 0.92;
		gravityMul*=0.5;
		initLife( Std.int(Const.db.RunnerHP) );
		spr.set(dict.testMob);
	}

	override function onDamage(dmg:Int, from:Entity) {
		super.onDamage(dmg, from);

		fx.mobHit(centerX, centerY, lastHitDirFromSource);

		if( !cd.hasSetS("repel",0.3) ) {
			dx*=0.5;
			bump(-dirTo(hero)*0.2, 0);
		}
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
		fx.lightLand(attachX, attachY);
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
			// Take aggro
			if( distCase(hero)<=7 && M.iabs(cy-hero.cy)<=2 && sightCheck(hero) ) {
				aggro();
			}

			// Aggro fast hops
			if( hasAggro() && onGround ) {
				if( dir!=dirTo(hero) ) {
					// Turn to target
					dir = dirTo(hero);
					setSquashX(0.4);
					lockAiS(0.8);
				}
				else {
					dx = dir*0.2;
					dy = -0.17;
					setSquashY(0.5);
					lockAiS(0.3);
				}
			}

			// Wandering small hops
			if( !hasAggro() && onGround ) {
				if( getDistToPlatformEnd(dir)<=1 )
					dir*=-1;

				dx = dir*0.12;
				dy = -0.1;
				setSquashX(0.7);
				lockAiS(0.9);
			}
		}
	}

}