package gm.en.int;

class BreakableGround extends Entity {
	public var data : Entity_BreakableGround;
	var cWid = 0;
	var fakes : Array<HSprite> = [];

	public function new(d:Entity_BreakableGround) {
		super(d.cx,d.cy);
		data = d;

		setPosPixel(data.pixelX, data.pixelY);
		collides = false;
		gravityMul = 0;
		triggerId = data.f_triggerId;
		Game.ME.scroller.add(spr, Const.DP_BG);
		pivotX = data.pivotX;
		pivotY = data.pivotY;

		cWid = M.round(d.width / Const.GRID);
		wid = cWid*Const.GRID;
		setCollisions(true);

		for(x in cx...cx+cWid) {
			level.setMark(HDoorZone, x,cy);
			var s = Assets.tiles.h_get(data.f_grassTexture ? dict.fakeGrass : dict.fakeGround, spr);
			s.x = (x-cx)*Const.GRID;
		}

		// Left side
		if( !level.hasWallCollision(cLeft-1,cTop) ) {
			var s = Assets.tiles.h_get(data.f_grassTexture ? dict.fakeGrassEnd : dict.fakeGroundEnd,0, 1,0, spr);
			s.scaleX = -1;
		}
		else
			Assets.tiles.h_get(data.f_grassTexture ? dict.fakeGrassLeft : dict.fakeGroundLeft,0, 1,0, spr);

		// Right side
		if( !level.hasWallCollision(cRight+1,cTop) ) {
			var s = Assets.tiles.h_get(data.f_grassTexture ? dict.fakeGrassEnd : dict.fakeGroundEnd,0, 0,0, spr);
			s.x = right-left;
		}
		else {
			var s = Assets.tiles.h_get(data.f_grassTexture ? dict.fakeGrassRight : dict.fakeGroundRight,0, 0,0, spr);
			s.x = right-left;
		}

	}

	override function trigger() {
		super.trigger();
		breakGround();
	}

	override function dispose() {
		super.dispose();
		setCollisions(false);
	}

	function setCollisions(set:Bool) {
		if( level==null || level.destroyed )
			return;

		for(i in 0...cWid)
			level.setCollisionOverride(cx+i, cy, set);
	}

	public function breakGround() {
		setCollisions(false);

		// Fog
		level.clearFogUpdateDelay();
		for(y in cy-1...cy+1)
		for(x in cx-2...cx+3)
			level.revealFog(x,y);

		// Fx
		if( data.f_explosion ) {
			fx.explosion(centerX, centerY);
			fx.flashBangS(0xffcc00, 0.2, 0.6);
			camera.shakeS(2.5, 0.6);
		}
		for(x in cx...cx+cWid)
			if( data.f_grassTexture )
				fx.grassExplosion(x, cy, 0x10d275, 0x007899);
			else
				fx.groundExplosion(x, cy, 0xd62411, 0x002859);

		// Bump
		if( data.f_bumpPlayer && hero.isAlive() && distCase(hero)<=4 ) {
			var pow = 0.5 + 0.5*(1-distCase(hero)/4);
			hero.bump( (centerX>hero.centerX ? -1 : 1) * 0.4*pow, -0.2*pow );
		}

		// Base slow mo
		if( data.f_autoSlowMo )
			game.addSlowMo("ground", 0.8, 0.4);

		// Fireballs
		if( data.f_fireballs )
			for(x in cx...cx+cWid) {
				var e = new FallingWreck((x+0.5)*Const.GRID, top+rnd(0,Const.GRID));
				e.gravityMul*=rnd(0.5,1);
			}

		destroy();
	}

	override function postUpdate() {
		super.postUpdate();
	}
}