package gm.en.mob;

class Fly extends gm.en.Mob {
	var ang = 0.;
	var target : LPoint;
	var wings : HSprite;
	var flyHeight = 0.;

	public function new(d:Entity_Mob) {
		super(d);
		frict = Const.db.FlyFrict;
		hei = Const.GRID*0.5;
		gravityMul = 0;
		collides = false;
		initLife( Std.int(Const.db.FlyHP) );
		target = this.createPoint();
		lockAiS(0);
		setPivots(0.5, 0.5);

		wings = Assets.mobs.h_getAndPlay(anims.flyWings, 999999);
		wings.setCenterRatio(0.5,0.5);
		game.scroller.add(wings, Const.DP_ENTITY_FRONT);
		wings.alpha = 0.5;

		spr.anim.registerStateAnim(anims.flyIdle, 0);
	}

	override function dispose() {
		super.dispose();
		wings.remove();
	}

	override function onDamage(dmg:Int, from:Entity) {
		super.onDamage(dmg, from);

		fx.mobHit(centerX, centerY, lastHitDirFromSource);

		if( !cd.hasSetS("repel",0.3) ) {
			dx*=0.7;
			dy*=0.7;
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

	function getShootAng() {
		return M.PIHALF - dir*0.4;
	}

	override function postUpdate() {
		super.postUpdate();

		wings.x = spr.x;
		wings.y = spr.y;

		if( !cd.hasSetS("fxTail",0.03) )
			fx.tail(this, 0xff0000);

		if( cd.has("spraying") && !cd.hasSetS("sprayFx",0.03) ) {
			fx.flyFireSpray(centerX, centerY, getShootAng(), getSprayRangePx());
			fx.flyFireSpray(centerX, centerY, getShootAng()+Const.db.FlySprayAng*0.5, getSprayRangePx());
			fx.flyFireSpray(centerX, centerY, getShootAng()-Const.db.FlySprayAng*0.5, getSprayRangePx());
		}

		if( isChargingAction() ) {
			if( !cd.hasSetS("blinkWarn",0.1) )
				blink(0xffcc00);
			spr.x+=rnd(0,1,true);
			spr.y+=rnd(0,1,true);
		}
	}

	function getSprayRangePx() {
		return Const.db.FlySprayRange * Const.GRID;// * ( 0.5 + 0.5*(1-cd.getRatio("spraying")) );
	}

	var heroHitS = 0.;
	override function fixedUpdate() {
		super.fixedUpdate();

		// Fire damage
		if( cd.has("spraying") && hero.isAlive() && distPx(hero)<=getSprayRangePx()-0.5 && M.radDistance(Math.atan2(hero.attachY-attachY,hero.attachX-attachX), getShootAng()) <= Const.db.FlySprayAng*0.4 ) {
			heroHitS+=1/Const.FIXED_UPDATE_FPS;
			if( !cd.hasSetS("fireFlash",0.1) )
				fx.flashBangS(0xff0000, 0.1, 0.2);
			hero.cd.setS("burning",1);
			if( heroHitS>=0.2 )
				hero.hit(1,this);
		}
		else
			heroHitS = 0;

		if( !cd.hasSetS("flyHeightLock",rnd(1,4)) )
			flyHeight = rnd(1.7, 3)*Const.GRID;

		// Look at hero
		if( !cd.has("spraying") )
			dir = dirTo(hero);

		// Fly
		if( !aiLocked() ) {
			target.levelX = hero.centerX - dirTo(hero)*16;
			target.levelY = hero.top - flyHeight;
			ang += M.radSubstract( Math.atan2(target.levelY-attachY, target.levelX-attachX), ang ) * Const.db.FlyAngSpeed;
			var spd = Const.db.FlyMoveSpeed * ( cd.has("spraying") ? Const.db.FlySpeedMulWhileSpraying : 1 );
			dx+=Math.cos(ang) * spd;
			dy+=Math.sin(ang) * spd;
			if( !cd.has("spraying") && distPx(target.levelX, target.levelY)<=10 ) {
				dx*=0.4;
				dy*=0.4;
				chargeAction("spray", Const.db.FlyCharge, ()->{
					cd.setS("spraying",1);
				});
			}
		}

		// if( isChargingAction() ) {
		// 	dx*=0.7;
		// 	dy*=0.7;
		// }


		// if( level.hasAnyCollision( Std.int(cx+xr+Math.cos(ang)*0.2), Std.int(cy+yr+Math.sin(ang)*0.2) ) )
	}

}