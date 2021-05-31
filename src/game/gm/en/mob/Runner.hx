package gm.en.mob;

class Runner extends gm.en.Mob {
	public function new(d:Entity_Mob) {
		super(d);
		frictX = 0.98;
		frictY = 0.92;
		hei = Const.GRID*0.5;
		gravityMul*=0.5;
		initLife( Std.int(Const.db.RunnerHP) );

		spr.anim.registerStateAnim(anims.runnerCharge, 2, ()->isChargingAction("jumpAtk"));
		spr.anim.registerStateAnim(anims.runnerJump, 1, ()->!onGround);
		spr.anim.registerStateAnim(anims.runnerIdle, 0);
	}

	override function onDamage(dmg:Int, from:Entity) {
		super.onDamage(dmg, from);

		fx.mobHit(centerX, centerY, lastHitDirFromSource);

		if( !cd.hasSetS("repel",0.3) ) {
			dx*=0.7;
			// bump(-dirTo(hero)*0.2, 0);
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

	override function onAggroStart() {
		super.onAggroStart();
		cd.setS("jumpAtk",rnd(0.5,1.2));
	}

	override function onTouchWall(wallDir:Int) {
		super.onTouchWall(wallDir);

		if( !hasAggro() ) {
			// dir = -wallDir;
			dx *= -1;
		}
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

		if( isChargingAction("jumpAtk") ) {
			if( !cd.hasSetS("chargeFx",0.06) )
				fx.sweat(this,0xffcc00);
			spr.x+=rnd(0,1,true);
		}
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		if( onGround )
			dx*=0.7;

		if( !aiLocked() ) {
			// Take aggro
			if( distCase(hero)<=7 && M.iabs(cy-hero.cy)<=2 && sightCheck(hero) )
				aggro();

			// Aggro fast hops
			if( hasAggro() && onGround ) {
				if( dir!=dirTo(hero) ) {
					// Turn to target
					dir = dirTo(hero);
					setSquashX(0.4);
					lockAiS(0.8);
				}
				else {
					if( !cd.hasSetS("jumpAtk",3) ) {
						// Big jump
						hud.notify("charge");
						chargeAction("jumpAtk",0.6, ()->{
							dx = dir*0.2;
							dy = -0.4;
							setSquashY(0.5);
							lockAiS(0.6);
						});
					}
					else {
						dx = dir*0.2;
						dy = -0.17;
						setSquashY(0.5);
						lockAiS(0.3);
					}
				}
			}

			// Wandering small hops
			if( !hasAggro() && onGround ) {
				if( getDistToPlatformEnd(dir)<=0 )
					dir*=-1;

				dx = dir*0.12;
				dy = -0.1;
				setSquashX(0.7);
				lockAiS(0.9);
			}
		}
	}

}