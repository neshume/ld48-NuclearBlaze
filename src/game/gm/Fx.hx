package gm;

import h2d.Sprite;
import dn.heaps.HParticle;


class Fx extends dn.Process {
	var game(get,never) : Game; inline function get_game() return Game.ME;
	var level(get,never) : Level; inline function get_level() return Game.ME.level;

	final dict = Assets.tilesDict;

	var pool : ParticlePool;
	var windX = 0.;

	public var bgAddSb    : h2d.SpriteBatch;
	public var bgNormalSb    : h2d.SpriteBatch;
	public var topAddSb       : h2d.SpriteBatch;
	public var topNormalSb    : h2d.SpriteBatch;

	public function new() {
		super(Game.ME);

		pool = new ParticlePool(Assets.tiles.tile, 2048, Const.FPS);

		bgAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bgAddSb, Const.DP_FX_BG);
		bgAddSb.blendMode = Add;
		bgAddSb.hasRotationScale = true;

		bgNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bgNormalSb, Const.DP_FX_BG);
		bgNormalSb.hasRotationScale = true;

		topNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(topNormalSb, Const.DP_FX_FRONT);
		topNormalSb.hasRotationScale = true;

		topAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(topAddSb, Const.DP_FX_FRONT);
		topAddSb.blendMode = Add;
		topAddSb.hasRotationScale = true;
	}

	override public function onDispose() {
		super.onDispose();

		pool.dispose();
		bgAddSb.remove();
		bgNormalSb.remove();
		topAddSb.remove();
		topNormalSb.remove();
	}

	/** Clear all particles **/
	public function clear() {
		pool.killAll();
	}

	/** Create a HParticle instance in the TOP layer, using Additive blendmode **/
	public inline function allocTopAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topAddSb, t, x, y);
	}

	/** Create a HParticle instance in the TOP layer, using default blendmode **/
	public inline function allocTopNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topNormalSb, t,x,y);
	}

	/** Create a HParticle instance in the BG layer, using Additive blendmode **/
	public inline function allocBgAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgAddSb, t,x,y);
	}

	/** Create a HParticle instance in the BG layer, using default blendmode **/
	public inline function allocBgNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgNormalSb, t,x,y);
	}

	/** Gets a random tile variation from the atlas **/
	public inline function getTile(id:String) : h2d.Tile {
		return Assets.tiles.getTileRandom(id);
	}

	public function markerEntity(e:Entity, ?c=0xFF00FF, ?short=false) {
		#if debug
		if( e==null )
			return;

		markerCase(e.cx, e.cy, short?0.03:3, c);
		#end
	}

	public function markerCase(cx:Int, cy:Int, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile(dict.fxCircle15), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.lifeS = sec;

		var p = allocTopAdd(getTile(dict.pixel), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(2);
		p.lifeS = sec;
		#end
	}

	public function markerFree(x:Float, y:Float, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile(dict.fxDot), x,y);
		p.setCenterRatio(0.5,0.5);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(3);
		p.lifeS = sec;
		#end
	}

	public function markerText(cx:Int, cy:Int, txt:String, ?t=1.0) {
		#if debug
		var tf = new h2d.Text(Assets.fontTiny, topNormalSb);
		tf.text = txt;

		var p = allocTopAdd(getTile(dict.fxCircle15), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.colorize(0x0080FF);
		p.alpha = 0.6;
		p.lifeS = 0.3;
		p.fadeOutSpeed = 0.4;
		p.onKill = tf.remove;

		tf.setPosition(p.x-tf.textWidth*0.5, p.y-tf.textHeight*0.5);
		#end
	}

	inline function collides(p:HParticle, offX=0., offY=0.) {
		return level.hasAnyCollision( Std.int((p.x+offX)/Const.GRID), Std.int((p.y+offY)/Const.GRID) );
	}

	public function flashBangS(c:UInt, a:Float, ?t=0.1) {
		var e = new h2d.Bitmap(h2d.Tile.fromColor(c,1,1,a));
		game.root.add(e, Const.DP_FX_FRONT);
		e.scaleX = game.w();
		e.scaleY = game.h();
		e.blendMode = Add;
		game.tw.createS(e.alpha, 0, t).end( function() {
			e.remove();
		});
	}


	public function itemPickUp(x:Float, y:Float, color:UInt) {
		var p = allocTopAdd(getTile(dict.fxStar), x,y);
		p.colorize(color);
		p.scale = 2;
		p.scaleMul = rnd(0.96,0.97);
		p.dr = rnd(0.2,0.3,true);
		p.rotation = rnd(0, M.PI,true);
		p.lifeS = vary(0.5);

		for(i in 0...80) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,3,true), y+rnd(0,3,true) );
			p.alpha = rnd(0.4,1);
			p.colorAnimS(color, 0x762087, rnd(0.6, 3)); // fade particle color from given color to some purple
			p.moveAwayFrom(x,y+8, rnd(1,3)); // move away from source
			p.frict = rnd(0.8, 0.9); // friction applied to velocities
			p.gy = rnd(0, 0.06); // gravity Y (added on each frame)
			p.lifeS = rnd(2,3); // life time in seconds
			p.onUpdate = _waterPhysics;
		}
	}


	public function dotsExplosion(x:Float, y:Float, color:UInt) {
		for(i in 0...80) {
			var p = allocTopAdd( getTile(dict.fxDot), x+rnd(0,3,true), y+rnd(0,3,true) );
			p.alpha = rnd(0.4,1);
			p.colorAnimS(color, 0x762087, rnd(0.6, 3)); // fade particle color from given color to some purple
			p.moveAwayFrom(x,y, rnd(1,3)); // move away from source
			p.frict = rnd(0.8, 0.9); // friction applied to velocities
			p.gy = rnd(0, 0.02); // gravity Y (added on each frame)
			p.lifeS = rnd(2,3); // life time in seconds
		}
	}


	public function touchPlate(x:Float, y:Float) {
		var n = 10;
		var range = M.PI*0.7;
		for(i in 0...n) {
			var a = -M.PIHALF - range*0.5 + range*i/(n-1);
			var p = allocTopAdd( getTile(dict.fxLine), x+Math.cos(a)*4, y+Math.sin(a)*4 );
			p.setCenterRatio(0.3,0.5);
			p.alpha = i%2==0 ? 0.6 : 1;
			p.colorize(0x46afff);
			p.scaleX = 0.2 + (i%2==0 ? 0.4 : 0);
			p.scaleXMul = 0.94;
			p.rotation = a;
			p.moveAng(a, 3.2);
			p.frict = 0.8;
			p.lifeS = around(0.2);
		}
	}



	public function doorOpened(x:Float, y:Float, h:Float, dir:Int) {
		var n = 9;
		var range = M.PI*0.3;
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxLine), x-dir*3, y-4 - (h-12)*i/(n-1) + rnd(0,1,true) );
			p.alpha = around(0.2);
			p.colorize(0x46afff);
			p.scaleX = around(0.6);
			p.scaleXMul = 0.96;
			p.moveAwayFrom(x-dir*20, y-h*0.5, around(3));
			p.rotation = p.getMoveAng();
			p.frict = 0.87;
			p.lifeS = around(0.2);
		}
	}


	inline function compressUp(ratio:Float, range:Float) return (1-range) + range*ratio;

	public inline function fireVanish(cx:Int, cy:Int, strong=false) {
		// Halo
		for(i in 0...3) {
			var p = allocTopAdd( getTile(dict.fxSmokeHalo), (cx+0.5)*Const.GRID+rnd(0,1,true), (cy+0.2)*Const.GRID+rnd(0,1,true) );
			p.setFadeS(vary(0.1), 0.03, rnd(0.5,1));
			p.colorize(0xc3b9a0);
			p.setScale(around(0.4));
			p.ds = around(0.14, 5);
			p.dsFrict = rnd(0.90, 0.92);
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0.02,0.03,true);
			p.lifeS = vary(0.1);
		}

		// Lines
		var n = Std.int( strong ? around(50) : around(7) );
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxLineDir), (cx+0.5)*Const.GRID+rnd(0,1,true), (cy+0.2)*Const.GRID+rnd(0,1,true));
			p.colorize( randColor(0xff0000,0xffcc00) );
			p.setFadeS( around(0.7), 0.1, around(0.7));
			p.moveAng( 0.3 - i/(n-1)*(M.PI+0.6) + zeroTo(0.1,true), around(1.6) );
			p.scaleX = around(0.2);
			p.gx = rnd(0.01, 0.06,true);
			p.gy = rnd(0.01, 0.06,true);
			p.autoRotateSpeed = 0.7;
			p.scaleXMul = aroundBelowOne(0.98);
			p.frict = aroundBelowOne(0.93);
			p.lifeS = around(0.1);
		}

		// Long smoke
		for(i in 0...8) {
			var p = allocTopNormal( getTile(dict.fxSmoke), getFlameX(cx,cy), getFlameY(cx,cy) );
			p.setFadeS(around(0.25), around(0.04), rnd(2,3));
			p.colorAnimS(0xc34029, 0xc3b9a0, rnd(0.1,0.5));
			p.setScale( around(0.75) );
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0,0.03,true);
			p.ds = rnd(0.002, 0.004);
			p.gx = windX * rnd(0,0.003);
			p.dy = -rnd(0.1, 0.3);
			p.frict = rnd(0.99,1);
			p.lifeS = rnd(0.3,0.6);
			p.delayS = rnd(0,0.4);
		}
	}

	public inline function levelFireSmoke(cx:Int,cy:Int, fs:FireState) {
		var pow = fs.getPowerRatio(true);

		var p = allocTopNormal( getTile(dict.fxSmoke), getFlameX(cx,cy), getFlameY(cx,cy) );
		p.setFadeS(rnd(0.4, 0.6)*compressUp(pow,0.7), rnd(0.3,0.5), rnd(0.4,1));
		// p.colorAnimS(0xc14132, 0x57546f, rnd(0.4, 1.2));
		p.colorAnimS(0xc14132, 0x0, rnd(0.4, 1.2));
		p.setScale(rnd(1,2,true));
		p.rotation = rnd(0,M.PI2);
		p.dr = rnd(0,0.03,true);
		p.ds = rnd(0.002, 0.004);
		p.gx = windX*rnd(0.01,0.02);
		p.dy = -rnd(0.3, 0.8) * compressUp(pow,0.8);
		p.frict = rnd(0.99,1);
		p.lifeS = rnd(0.3,0.6);
		p.delayS = rnd(0,0.4);
	}

	public inline function levelExtinguishedSmoke(x:Float,y:Float, fs:FireState) {
		var p = allocBgNormal( getTile(dict.fxSmoke), x+rnd(0,8,true), y-rnd(0,10) );
		p.setFadeS(rnd(0.4, 0.6), rnd(0.4,0.6), rnd(0.8,1));
		p.colorAnimS(0x4d4959, 0x0, rnd(0.8, 1.2));
		p.setScale(rnd(1,2,true));
		p.rotation = rnd(0,M.PI2);
		p.dr = rnd(0,0.02,true);
		p.ds = rnd(0.002, 0.004);
		p.gx = windX*rnd(0.01,0.02);
		p.gy = -rnd(0.01, 0.02);
		p.frict = rnd(0.97,0.98);
		p.lifeS = rnd(0.3,0.6);
		p.delayS = rnd(0,0.4);

		var p = allocBgAdd( getTile(dict.pixel), x+rnd(0,8,true), y+rnd(0,1) );
		p.setFadeS(rnd(0.3, 0.6), rnd(0.1,0.2), rnd(0.4,0.6));
		p.colorize( C.interpolateInt(0xff0000,0xffcc00, rnd(0,1)) );
		p.alphaFlicker = 0.2;
		p.lifeS = rnd(0.3,0.6);
		p.delayS = rnd(0,0.6);
	}

	public inline function levelFireSparks(cx:Int, cy:Int, fs:FireState) {
		var pow = fs.getPowerRatio(true);

		for(i in 0...M.round(1+pow)) {
			var p = allocTopAdd( getTile(dict.pixel), getFlameX(cx,cy), getFlameY(cx,cy) );
			p.colorAnimS(0xff8800, 0xff0044, rnd(0.3,1));
			p.setFadeS(rnd(0.7,1), 0.1, 0.3);
			p.alphaFlicker = 0.6;
			p.dx = rnd(-0.8,0.4) * compressUp(pow,0.5);
			p.dy = -rnd(0.6, 5) * compressUp(pow,0.5);
			p.gx = rnd(0,0.05,true);
			p.frict = rnd(0.8, 0.96);
			p.lifeS = rnd(0.2,0.3);
			p.delayS = rnd(0, 0.5);
		}
	}

	inline function getFlameX(cx:Int,cy:Int) {
		return Const.GRID * (
			level.hasAnyCollision(cx-1,cy) ? rnd(cx-0.2,cx+0.1) :
			level.hasAnyCollision(cx+1,cy) ? rnd(cx+0.9,cx+1.2) :
			rnd(cx-0.1,cx+1.1)
		);
	}
	inline function getFlameY(cx:Int,cy:Int) {
		return Const.GRID * (
			level.hasAnyCollision(cx,cy-1) ? rnd(cy,cy+1) :
			level.hasAnyCollision(cx,cy+1) ? rnd(cy+1,cy+1.4) :
			rnd(cy-0.2,cy+1.2)
		);
	}

	public inline function levelFlames(cx:Int,cy:Int, fs:FireState, strong=false) {
		final maxed = fs.level>=2;
		var pow = fs.getPowerRatio(true);
		var baseCol = !maxed ? 0xff0000 : C.interpolateInt(0xff6200,0xffcc33,rnd(0,1));
		var finalCol = 0xb71919;
		if( fs.oil ) {
			baseCol = 0x6922ff;
			finalCol = 0x4a6eb5;
		}

		var n = Std.int(1+pow*3);
		if( !level.hasAnyCollision(cx,cy+1) )
			n+=2;

		if( strong )
			n = 10;

		for( i in 0...n ) {
			var p = allocTopAdd( getTile(dict.fxFlame), getFlameX(cx,cy), getFlameY(cx,cy) );
			p.setFadeS(maxed ? rnd(0.9,1) : rnd(0.7,0.8), rnd(0.2,0.4), 0.3);
			p.colorAnimS( baseCol, finalCol, rnd(0.3,0.6) );
			p.setScale(rnd(0.9,2) * compressUp(pow,0.7));
			p.scaleX *= rnd(0.7,1.4,true);
			p.rotation = -rnd(0.1,0.2);
			p.scaleMul = rnd(0.94,0.96);
			p.dsY = rnd(0.01,0.02);
			p.dsFrict = 0.92;
			p.dx = rnd(0,0.2,true) + windX*0.2;
			p.dy = i==0
				? -rnd(0.7, 0.9) * compressUp(pow,0.7)
				: -rnd(0.2, 1.4) * compressUp(pow,0.5);
			p.frict = rnd(0.94, 0.98);
			p.lifeS = rnd(0.3,0.5);
			p.delayS = rnd(0,0.4);
		}
	}

	inline function vary(maxValue:Float, pct=0.1) {
		return maxValue * rnd(1-pct, 1);
	}

	inline function randCircle() return rnd(0,M.PI2);
	inline function randHalfCircle() return rnd(0,M.PI);
	inline function randQuarterCircle() return rnd(0,M.PIHALF);

	inline function around(v:Float, pct=10) {
		return v * ( 1 + rnd(0,pct/100,true) );
	}

	inline function aroundBelowOne(v:Float, pct=10) {
		return M.fmin( 1, v * ( 1 + rnd(0,pct/100,true) ) );
	}

	inline function zeroTo(v:Float, sign=false) {
		return rnd(0,v,sign);
	}

	inline function randColor(minColor:UInt, maxColor:UInt) : UInt {
		return C.interpolateInt( minColor, maxColor, rnd(0,1) );
	}

	public function upgradeHalo(x:Float, y:Float) {
		for(i in 0...4) {
			var a = randCircle();
			var p = allocTopAdd( getTile(dict.fxLineDir), x,y );
			p.setFadeS( around(0.5), 0.3, 0.4 );
			p.colorize(0xff8800);
			p.setCenterRatio(1.3, 0.5);

			p.rotation = a+M.PI;
			p.scaleX = around(0.2);
			p.dr = zeroTo(0.01,true);
			p.dsX = around(0.1);
			p.dsFrict = aroundBelowOne(0.76);
			p.scaleXMul = rnd(0.985,0.999);
			p.lifeS = around(0.4);

		}
	}

	public inline function lightSmoke(x:Float,y:Float, c:UInt) {
		var p = allocBgAdd( getTile(dict.fxSmoke), x+rnd(8,20,true), y+rnd(8,20,true) );
		p.setFadeS(around(0.1), rnd(0.4,0.6), rnd(0.8,1));
		p.colorize(c);
		p.setScale(rnd(1,2,true));
		p.rotation = rnd(0,M.PI2);
		p.dr = rnd(0,0.02,true);
		p.ds = rnd(0.002, 0.004);
		p.gx = around(0.010);
		p.gy = around(0.015);
		p.frict = aroundBelowOne(0.94);
		p.lifeS = rnd(0.3,0.6);
	}

	public inline function lightFlare(x:Float,y:Float, c:UInt) {
		var p = allocBgAdd( getTile(dict.fxFlare), x+rnd(0,2,true), y );
		p.setFadeS(around(0.1), 0.2, around(0.5));
		p.colorize(c);
		p.scaleX = rnd(0.3,0.7,true) * ( 0.7 + 0.3*Math.cos(ftime*0.3) );
		p.lifeS = around(0.2);
	}


	public function waterShoot(x:Float, y:Float, ang:Float) {
		for(i in 0...3) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,2,true), y+rnd(0,2,true));
			p.setFadeS(rnd(0.6,0.9), 0.03, around(0.1));
			p.moveAng( ang + rnd(0.2, 1.3, true), around(0.7));
			p.frict = aroundBelowOne(0.8);
			p.colorize(Const.WATER_COLOR);
			p.lifeS = around(0.07);
		}

		for(i in 0...4) {
			var p = allocTopAdd( getTile(dict.fxLineDir), x, y);
			p.setFadeS(aroundBelowOne(0.7), 0.03, around(0.1));
			p.scaleX = around(0.25);
			p.scaleY = rnd(1,2);
			p.moveAng( ang + rnd(0.1, 0.6, true), around(2));
			p.scaleXMul = aroundBelowOne(0.97);
			p.autoRotateSpeed = 1;
			p.frict = aroundBelowOne(0.8);
			p.colorize(Const.WATER_COLOR);
			p.lifeS = around(0.07);
		}
	}

	public function waterTail(lastX:Float, lastY:Float, curX:Float, curY:Float, elapsed:Float, col:UInt) {
		var alpha = compressUp( 1 - elapsed, 0.8 );
		var d = M.dist(curX, curY, lastX, lastY);
		var a = Math.atan2(curY-lastY, curX-lastX);

		// Tail core
		var p = allocTopAdd( getTile(dict.fxTail), lastX, lastY);
		p.setFadeS(vary(0.4)*alpha, 0, 0.1);
		p.colorize(col);
		p.setCenterRatio(0.2,0.5);
		p.rotation = a;
		p.scaleX = (d+17)/p.t.width;
		p.scaleY = vary(0.7);
		p.scaleYMul = vary(0.96);
		p.lifeS = around(0.2);

		// Dots
		var off = rnd(0.5,2,true);
		var p = allocTopAdd( getTile(dict.pixel), (lastX+curX)*0.5 + Math.cos(a+M.PIHALF)*off, (lastY+curY)*0.5+Math.sin(a+M.PIHALF)*off);
		p.setFadeS( vary(0.7)*alpha, 0, 0.1);
		p.colorize(col);
		p.moveAng(a, rnd(1,3));
		p.frict = vary(0.8);
		p.gy = rnd(0.1,0.2);
		p.onUpdate = _waterPhysics;
		p.lifeS = rnd(0.06,0.10);

		// Line
		var offX = rnd(0,5,true);
		var offY = rnd(0.5,2,true);
		var p = allocTopAdd(
			getTile(dict.fxLineDir),
			(lastX+curX)*0.5 + Math.cos(a+M.PIHALF)*offY + Math.cos(a)*offX,
			(lastY+curY)*0.5+Math.sin(a+M.PIHALF)*offY + Math.sin(a)*offX
		);
		p.setFadeS( vary(0.4)*alpha, 0, 0.1);
		p.colorize(col);
		p.rotation = a;
		p.scaleX = d / p.t.width;
		// p.scaleX = vary(0.2);
		p.scaleMul = rnd(1.02,1.03);
		p.frict = vary(0.8);
		p.lifeS = rnd(0.06,0.10);
	}

	function _waterPhysics(p:HParticle) {
		if( p.data0!=1 && collides(p) ) {
			p.data0 = 1;
			p.dx = p.dy = 0;
			p.gy = 0;
			p.autoRotateSpeed = 0;
			p.setScale( rnd(2,3) );
			p.scaleMul = vary(0.96, 0.05);
			p.rotation = rnd(0,M.PI);
			p.maxAlpha *= 0.4;
		}
	}

	public function wallSplash(x:Float, y:Float) {
		for(i in 0...irnd(5,8)) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,3,true), y+rnd(0,3,true) );
			p.setFadeS(rnd(0.3,0.4), 0, 0.1);
			p.moveAwayFrom(x,y, rnd(1,2));
			p.gy = rnd(0.04,0.10);
			p.frict = vary(0.9);
			p.colorize(Const.WATER_COLOR);
			p.onUpdate = _waterPhysics;
			p.lifeS = rnd(0.1,0.3);
		}
	}

	public function waterVanish(x:Float, y:Float) {
		for(i in 0...2) {
			var p = allocTopAdd( getTile(dict.fxSmoke), x+rnd(0,3,true), y+rnd(0,3,true));
			p.setFadeS( vary(0.1), 0.1, 0.2);
			p.colorize(Const.WATER_COLOR);
			p.rotation = rnd(0,M.PI2);
			p.setScale(vary(0.6));
			p.dr = rnd(0.01,0.02,true);
			p.dy = -vary(0.5);
			p.lifeS = 0.2;
		}
	}

	public function fireSplash(x:Float, y:Float) {
		var p = allocTopAdd( getTile(dict.fxSmoke), x,y);
		p.setFadeS( vary(0.1), 0, 0.1);
		p.colorize(Const.WATER_COLOR);
		p.rotation = rnd(0,M.PI2);
		p.setScale(vary(0.8));
		p.lifeS = 0.1;

		for(i in 0...irnd(8,10)) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,3,true), y+rnd(0,3,true) );
			p.setFadeS(rnd(0.7,1), 0, 0.1);
			p.moveAwayFrom(x,y, rnd(1,2));
			p.gy = rnd(0.04,0.10);
			p.frict = vary(0.9);
			p.colorize(Const.WATER_COLOR);
			p.onUpdate = _waterPhysics;
			p.lifeS = rnd(0.1,0.3);
		}
	}

	public function oilIgnite(cx,cy) {
		// Stars
		for(i in 0...20) {
			var p = allocTopAdd(getTile(dict.pixel), getFlameX(cx,cy)+rnd(0,2,true), getFlameY(cx,cy)+rnd(0,2,true)-3);
			p.alphaFlicker = 0.8;
			p.setFadeS( aroundBelowOne(0.9), 0, 0.1);
			p.colorize(0xff0000);
			p.dx = rnd(0,1,true);
			p.gy = around(0.05);
			p.dy = -around(0.5);
			p.frict = rnd(0.85,0.95);
			p.lifeS = around(0.3);
			p.delayS = i*0.05 + zeroTo(0.1,true);
		}
		// for(i in 0...12) {
		// 	var p = allocTopAdd(getTile(dict.fxStar), getFlameX(cx,cy)+rnd(0,4,true), getFlameY(cx,cy)+rnd(0,4,true)-8);
		// 	p.colorize(0x7860e7);
		// 	p.setScale(rnd(0.5,1));
		// 	p.dr = around(0.4) * rndSign();
		// 	p.dy = -around(2);
		// 	p.frict = rnd(0.75,0.85);
		// 	p.rotation = rnd(0, M.PI,true);
		// 	p.delayS = i * rnd(0,0.1);
		// 	p.lifeS = rnd(0.1,0.2);
		// }
	}


	public function explosion(x:Float,y:Float) {
		var r = Const.GRID*3;
		for(i in 0...12) {
			var d = i<=2 ? rnd(0,20) : rnd(0,r-10);
			var a = rnd(0,M.PI2);
			var p = allocBgAdd(getTile(dict.fxExplode), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.playAnimAndKill( Assets.tiles, dict.fxExplode, rnd(0.3,0.4) );
			p.setScale(rnd(0.9,2));
			p.rotation = rnd(0, 0.4, true);
			p.delayS = i*0.05 + rnd(0.1,0.2,true);
		}
	}


	function _dirtPhysics(p:HParticle) {
		if( collides(p) ) {
			p.dx *= Math.pow(rnd(0.8,0.9),tmod);
			p.dy = 0;
			p.gy = 0;
			p.dr *= Math.pow(0.8,tmod);
			p.lifeS = 0;
		}

		if( !collides(p) && ( collides(p,3,0) || collides(p,-3,0) ) ) {
			p.dx = -p.dx*0.6;
			p.dr*=-1;
		}
	}

	public function brokenDoor(x:Float, y:Float, dir:Int) {
		for(i in 0...40) {
			var p = allocTopNormal( getTile(dict.fxDirt), x+rnd(0,5,true), y+rnd(0,12,true));
			p.colorize(0x8f563b);
			p.setScale(vary(1));
			p.dx = dir*rnd(3,12);
			p.dy = rnd(-0.6,0.1);
			p.frict = vary(0.96);
			p.gy = rnd(0.05,0.1);
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0.1,0.4,true);
			p.setFadeS(vary(0.9), 0, vary(2));
			p.onUpdate = _dirtPhysics;
		}
	}


	public function doorExplosion(x:Float,y:Float, dir:Int) {
		for(i in 0...12) {
			var d = rnd(0,20);
			var a = rnd(0,M.PI2);
			var p = allocBgAdd(getTile(dict.fxExplode), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.alpha = rnd(0.4,0.7);
			p.playAnimAndKill( Assets.tiles, dict.fxExplode, rnd(0.3,0.4) );
			p.dx = dir*rnd(1,3);
			p.frict = rnd(0.9,0.94);
			p.setScale(rnd(0.9,2));
			p.rotation = rnd(0, 0.4, true);
			p.delayS = i*0.02 + rnd(0.,0.1,true);
		}

		// Flames
		for(i in 0...50) {
			var d = rnd(0,20);
			var a = rnd(0,M.PI2);
			var p = allocTopAdd(getTile(dict.fxFlame), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorizeRandom(0xff0000, 0xff9900);
			p.setFadeS(rnd(0.8,1), 0, vary(0.2));
			p.frict = rnd(0.8,0.94);
			p.dx = dir*rnd(3,15);
			p.dy = rnd(-1,0);
			p.scaleMul = rnd(0.98,0.99);
			p.gx = dir*rnd(0.02,0.03);
			p.gy = -rnd(0.02,0.03);
			p.setScale(rnd(0.9,2));
			p.rotation = p.getMoveAng() + M.PIHALF;
			p.delayS = rnd(0.1,0.3);
			p.lifeS = rnd(0.3,1);
		}
	}


	public function flame(x:Float,y:Float) {
		for(i in 0...9) {
			var p = allocTopAdd( getTile(dict.fxFlame), x+rnd(0,3,true), y+rnd(0,7,true) );
			p.setFadeS(rnd(0.3,0.5), 0.1, 0.2);
			p.colorAnimS( C.interpolateInt(0xff5500, 0xffcc00, rnd(0,1)), 0x9e62f1, rnd(0.2,0.4) );
			p.setScale(rnd(0.4,0.8));
			p.scaleX*=rndSign();
			p.rotation = -rnd(0.1,0.2);
			p.dx = -rnd(0.1,0.3);
			p.scaleMul = rnd(0.98,0.99);
			p.dy = -rnd(0.4, 1.3);
			p.frict = rnd(0.94, 0.96);
			p.lifeS = rnd(0.2,0.3);
			p.delayS = i==0 ? 0 : rnd(0,0.1);
		}
	}



	public function fireSpray(x:Float,y:Float, ang:Float, dist:Float) {
		// Core dots
		for(i in 0...2) {
			var p = allocTopAdd( getTile(dict.fxLine), x,y);
			p.colorAnimS( 0xffcc00, 0x9e62f1, around(0.3) );
			p.scaleX = around(0.1);
			p.setFadeS(around(0.9), 0.03, around(0.1));
			p.frict = aroundBelowOne(0.9);
			p.moveAng(ang, around(2));
			p.rotation = p.getMoveAng();
			p.lifeS = around(0.1);
			p.delayS = around(0.1);
		}

		// Sparks
		for(i in 0...3) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,1,true), y+rnd(0,1,true) );
			p.colorAnimS( 0xffcc00, 0xff0000, around(0.3) );
			p.setFadeS(around(0.9), 0.03, around(0.1));
			p.alphaFlicker = 0.6;
			p.scaleX = 2;

			p.frict = aroundBelowOne(0.9);
			p.moveAng(ang+rnd(0,1,true), rnd(0.5,2));
			p.gy = around(0.03);
			p.autoRotateSpeed = 1;

			p.lifeS = around(0.6);
			p.delayS = around(0.1);
		}

		// Flames
		var n = dist<=Const.GRID*1.5 ? 2 : 3;
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxFlame), x+rnd(0,2,true), y+rnd(0,2,true) );
			p.setFadeS(around(0.8), around(0.03), around(0.2));
			p.colorAnimS( C.interpolateInt(0xffdd88, 0xff4400, rnd(0,1)), 0x9e62f1, around(0.3) );
			p.rotation = -rnd(0.1,0.2);

			p.scaleX = around(0.3) * rndSign();
			p.scaleY = around(1);
			p.scaleYMul = rnd(0.96,0.98);
			// p.scaleYMul = rnd(1,1.03);

			p.moveAng(ang+zeroTo(0.05,true), 2.3*(dist/Const.GRID)+rnd(0,0.2,true));
			p.rotation = ang + M.PIHALF;
			p.frict = 0.85 + rnd(0,0.02);

			p.lifeS = around(0.2);
			p.delayS = i==0 ? 0 : around(0.06);
		}

	}


	override function update() {
		super.update();

		windX = Math.cos(ftime*0.01);
		pool.update(game.tmod);
	}
}