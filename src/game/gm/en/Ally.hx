package gm.en;

class Ally extends Entity {
	public static var ALL : Array<Ally> = [];

	var anims = dn.heaps.assets.Aseprite.getDict( hxd.Res.atlas.hero );
	var data : Entity_Ally;
	var spd : Float;
	var waterTarget : Null<LPoint>;

	public function new(d:Entity_Ally) {
		data = d;
		super(data.cx, data.cy);
		ALL.push(this);
		dir = data.f_dir;

		spr.set(Assets.hero);
		spr.anim.registerStateAnim(anims.jumpUp, 3, ()->!onGround && dy<0.1 );
		spr.anim.registerStateAnim(anims.jumpDown, 3, ()->!onGround && dy>=0.1 );
		spr.anim.registerStateAnim(anims.run, 2, 1.3, ()->onGround && M.fabs(dxTotal)>spd*2 );
		spr.anim.registerStateAnim(anims.idleCrouch, 1, ()->!cd.has("recentMove"));
		spr.anim.registerStateAnim(anims.idle, 0);

		spd = R.around(0.009, 5);
	}


	function lockAiS(t:Float) {
		cd.setS("aiLock",t,false);
	}

	public inline function aiLocked() {
		return cd.has("aiLock");
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}



	function shootWater(tx,ty) {
		var waterAng = Math.atan2(ty-cy, tx-cx);

		// Change dir
		if( tx<cx && dir==1 || tx>cx && dir==-1 )
			dir*=-1;

		if( !cd.hasSetS("bullet",0.09) ) {
			var adjustedAng = waterAng;
			if( !M.radCloseTo(adjustedAng, -M.PIHALF, M.PIHALF*0.3) )
				if( M.radCloseTo(adjustedAng, M.PIHALF, M.PIHALF*1.1))
					adjustedAng -= dir*0.1;
				else
					adjustedAng -= dir*0.2;

			var n = 3;
			var spread = 0.19;
			var shootX = centerX+dir*3;
			var shootY = centerY-1;
			for(i in 0...n) {
				var ang = adjustedAng  -  spread*0.5+spread*(i+1)/n  +  rnd(0, 0.05, true);
				var b = new gm.en.bu.WaterDrop(shootX, shootY, ang);
				b.dx*=0.9;
				b.dy*=0.9;
				b.gravityMul*=0.1;
				b.delayS(rnd(0,0.1));
				b.power	= 0;
				b.collides = false;
			}
			fx.waterShoot(shootX, shootY, adjustedAng);
		}
	}



	override function fixedUpdate() {
		super.fixedUpdate();

		// Pick water target
		if( waterTarget==null && !cd.hasSetS("fireCheck",0.5) ) {
			var dh = new dn.DecisionHelper( dn.Bresenham.getDisc(cx,cy, 6) );
			dh.keepOnly( pt->level.isBurning(pt.x,pt.y) && sightCheck(pt.x,pt.y) );
			dh.keepOnly( pt->M.radDistance(-M.PIHALF, Math.atan2(pt.y-cy, pt.x-cx)) >= 0.3 );
			dh.score( pt->-distCase(pt.x,pt.y)*0.2 );
			dh.score( pt->M.iabs(pt.y-cy)<=2 ? 2 : 0 );
			dh.score( pt->M.sign(dir)==M.sign(pt.x-cx) ? 1.5 : 0 );
			dh.score( pt->rnd(0,1) );
			// dh.iterateRemainings((pt,s)->fx.markerCase(pt.x,pt.y, 0.1, 0x880000));
			// dh.useBest( pt->fx.markerCase(pt.x,pt.y, 0.1, 0xffff00) );
			dh.useBest( pt->waterTarget = LPoint.fromCase(pt.x,pt.y) );
			cd.setS("watering",rnd(2,3));
		}

		// Shoot water
		if( waterTarget!=null && level.isBurning(waterTarget.cx,waterTarget.cy) )
			shootWater(waterTarget.cx, waterTarget.cy);

		// Stop watering
		if( waterTarget!=null && ( !cd.has("watering") || !level.isBurning(waterTarget.cx,waterTarget.cy) ) ) {
			cd.setS("fireCheck", rnd(1,3));
			waterTarget = null;
		}

		// Wandering
		if( waterTarget==null ) {
			// Panic state
			if( !cd.has("panicLock") ) {
				cd.setS("panic",rnd(2,4));
				cd.setS("panicLock", cd.getS("panic")+rnd(8,12));
			}

			// Wander: change dir
			if( onGround && !cd.has("walking") && !cd.hasSetS("dirChange",rnd(2,9)) )
				dir*=-1;

			// Wander: start to walk
			if( !cd.has("walking") && !cd.has("walkLock") ) {
				cd.setS("walking", rnd(1,2));
				cd.setS("walkLock", cd.getS("walking")+rnd(0.4,1));
			}

			// Wander: walk
			if( onGround && cd.has("walking") ) {
				dx += spd*dir * (cd.has("panic") ? 2 : 1);
				cd.setS("recentMove", 0.2);
				// Panic fx
				if( cd.has("panic") && !cd.hasSetS("panicFx",0.3) )
					fx.sweat(this);
			}


			// Wander: reach platform end
			if( cd.has("walking") && ( dir==1 && level.hasMark(PlatformEndRight,cx,cy) || dir==-1 && level.hasMark(PlatformEndLeft,cx,cy) ) ) {
				cd.unset("walking");
				cd.setS("walkLock", rnd(0.6,0.9));
				cd.setS("dirChange", rnd(0.3,0.5), true);
			}
		}
	}

}