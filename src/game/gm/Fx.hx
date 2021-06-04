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
	var graphics : h2d.Object;

	public function new() {
		super(Game.ME);

		pool = new ParticlePool(Assets.tiles.tile, 2500, Const.FPS);

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

		graphics = new h2d.Object();
		game.scroller.add(graphics, Const.DP_FX_FRONT);
		graphics.blendMode = Add;
	}

	override public function onDispose() {
		super.onDispose();

		pool.dispose();
		bgAddSb.remove();
		bgNormalSb.remove();
		topAddSb.remove();
		topNormalSb.remove();
		graphics.remove();
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
		p.lifeS = R.around(0.5);

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
			p.lifeS = R.around(0.2);
		}
	}



	public function doorOpened(x:Float, y:Float, h:Float, dir:Int) {
		var n = 9;
		var range = M.PI*0.3;
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxLine), x-dir*3, y-4 - (h-12)*i/(n-1) + rnd(0,1,true) );
			p.alpha = R.around(0.2);
			p.colorize(0x46afff);
			p.scaleX = R.around(0.6);
			p.scaleXMul = 0.96;
			p.moveAwayFrom(x-dir*20, y-h*0.5, R.around(3));
			p.rotation = p.getMoveAng();
			p.frict = 0.87;
			p.lifeS = R.around(0.2);
		}
	}


	inline function compressUp(ratio:Float, range:Float) return (1-range) + range*ratio;

	public inline function fireExtinguishedByWater(cx:Int, cy:Int, strong=false) {
		// Halo
		for(i in 0...3) {
			var p = allocTopAdd( getTile(dict.fxSmokeHalo), (cx+0.5)*Const.GRID+rnd(0,1,true), (cy+0.2)*Const.GRID+rnd(0,1,true) );
			p.setFadeS( R.around(0.1), 0.03, rnd(0.5,1) );
			p.colorize(0xc3b9a0);
			p.setScale(R.around(0.4));
			p.ds = R.around(0.14, 5);
			p.dsFrict = rnd(0.90, 0.92);
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0.02,0.03,true);
			p.lifeS = R.around(0.1);
		}

		// Splash
		var n = 9;
		var a = 0.;
		var d = 0.;
		var x = (cx+0.5)*Const.GRID;
		var y = (cy+0.5)*Const.GRID;
		for(i in 0...n) {
			a = (i+1)/n * M.PI2;
			d = rnd(3,6);
			var p = allocTopAdd(getTile(dict.fxFlame), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.setFadeS(R.around(0.4), 0, 0.1);
			p.colorize(0x50ccff);
			p.moveAng(a, rnd(3,4));
			p.rotation = a+M.PIHALF;
			p.frict = 0.77;
			p.scaleY = R.around(1.2);
			p.scaleYMul = R.aroundBO(0.96);
			p.lifeS = R.around(0.4);
		}

		// Lines
		var n = Std.int( strong ? R.around(50) : R.around(7) );
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxLineThinLeft), (cx+0.5)*Const.GRID+rnd(0,1,true), (cy+0.2)*Const.GRID+rnd(0,1,true));
			p.colorize( R.colorMix(0xff0000,0xffcc00) );
			p.setFadeS( R.around(0.7), 0.1, R.around(0.7));
			p.moveAng( 0.3 - i/(n-1)*(M.PI+0.6) + R.zeroTo(0.1,true), R.around(1.6) );
			p.scaleX = R.around(0.2);
			p.gx = rnd(0.01, 0.06,true);
			p.gy = rnd(0.01, 0.06,true);
			p.autoRotateSpeed = 0.7;
			p.scaleXMul = R.aroundZTO(0.98);
			p.frict = R.aroundZTO(0.93);
			p.lifeS = R.around(0.1);
		}

		// Long smoke
		for(i in 0...8) {
			var p = allocTopNormal( getTile(dict.fxSmoke), getFlameX(cx,cy), getFlameY(cx,cy) );
			p.setFadeS(R.around(0.10), R.around(0.04), rnd(2,3));
			p.colorAnimS(0xc34029, 0xc3b9a0, rnd(0.1,0.5));
			p.setScale( R.around(0.75) );
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

	public inline function levelExtinguishedSmoke(x:Float,y:Float, fs:FireState, pow=1.0, col=0x4d4959) {
		var p = allocBgNormal( getTile(dict.fxSmoke), x+rnd(0,8,true), y-rnd(0,10) );
		p.setFadeS( M.fmin(1, rnd(0.4, 0.6)*pow), rnd(0.4,0.6), rnd(0.8,1) );
		p.colorAnimS(col, 0x0, rnd(0.8, 1.2));
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


	public inline function smoke(x:Float,y:Float, fromColor=0x4d4959, toColor=0x0, wind=true) {
		var p = allocTopNormal( getTile(dict.fxSmoke), x+rnd(0,8,true), y-rnd(0,10) );
		p.setFadeS( rnd(0.1, 0.2), rnd(0.6,1), rnd(1,2) );
		p.colorAnimS(fromColor, toColor, rnd(0.8, 1.2));
		p.setScale(rnd(1,2,true));
		p.rotation = rnd(0,M.PI2);
		p.dr = rnd(0,0.02,true);
		p.ds = rnd(0.002, 0.004);
		if( wind )
			p.gx = windX*rnd(0.01,0.02);
		p.gy = -rnd(0.01, 0.02);
		p.frict = rnd(0.97,0.98);
		p.lifeS = rnd(1,2);
		p.delayS = rnd(0,0.4);
	}

	public inline function cloud(x:Float,y:Float, col:Int, dir:Int) {
		var p = allocTopNormal( getTile(dict.fxSmoke), x+rnd(0,8,true), y-rnd(0,10) );
		p.setFadeS( rnd(0.04, 0.10), rnd(0.8,1), rnd(1,2) );
		p.colorize(col);
		p.setScale(rnd(4,5,true));
		p.rotation = rnd(0,M.PI2);
		p.dx = dir * rnd(5,12);
		p.gx = dir * 0.01;
		// p.frict = R.aroundZTO(0.99, 5);
		p.lifeS = rnd(2,3);
		p.delayS = rnd(0,0.4);
	}

	public inline function speedLine(x:Float,y:Float, col:Int, dir:Int) {
		var p = allocTopNormal( getTile(dict.fxLine), x, y);
		p.setFadeS( rnd(0.2, 0.6), rnd(0.5,0.7), R.around(1.5) );
		p.colorize(col);
		p.scaleX = rnd(2,4);
		p.dx = dir * rnd(10,16);
		p.lifeS = R.around(1);
		p.delayS = rnd(0,0.4);
	}

	public inline function starField(x:Float,y:Float, col:Int, dir:Int) {
		var z = rnd(0,0.7);
		var p = allocBgAdd( getTile(dict.pixel), x, y );
		p.setFadeS( R.around(0.8)*(1-z), 0, R.around(0.2) );
		p.colorize(col);
		p.dx = dir * R.around(4, 5) * (1-z);
		p.lifeS = R.around(1+z*3);
		p.delayS = rnd(0,0.4);
	}

	public function helicopterRotorTop(x:Float,y:Float, dir:Int, col:Int) {
		var p = allocTopNormal( getTile(dict.fxHeliWings), x+rnd(0,1,true), y+rnd(0,1,true) );
		p.colorize(col);
		p.alpha = 0.5;
		p.playAnimLoop(Assets.tiles, dict.fxHeliWings, 0.4);
		p.scaleX = 3.5;
		p.scaleY = 0.22;
		p.lifeS = 0.5;
	}


	public function helicopterRotorBack(x:Float,y:Float, dir:Int, col:Int) {
		var p = allocTopNormal( getTile(dict.fxHeliWings), x+rnd(0,1,true), y+rnd(0,1,true) );
		p.colorize(col);
		p.alpha = 0.7;
		p.playAnimLoop(Assets.tiles, dict.fxHeliWings, 0.8);
		p.setScale(0.2);
		p.scaleX*=dir;
		p.lifeS = 0.5;
	}


	function _dustPhysics(p:HParticle) {
		if( collides(p) ) {
			p.dy *= Math.pow(0.9,tmod);
			p.gy *= Math.pow(0.8,tmod);
			p.scaleX = 1;
		}
		else if( p.dy>0 && collides(p,0,M.ceil(p.dy*2)) ) {
			if( p.data0>0 ) {
				p.dx = rnd(0.2,1,true) * p.data0;
				p.dy*=-0.6;
				p.scaleX = 1;
				p.data0 = 0;
			}
			else
				p.dy*=-0.3;
			p.gy *= Math.pow(0.8,tmod);
		}
	}

	public function walkDust(x:Float, y:Float, dir:Int, col=0xcbb5a0) {
		var p = allocBgNormal( getTile(dict.pixel), x, y );
		p.setFadeS(rnd(0.1,0.7), 0.06, R.around(0.2));
		p.colorize(col);
		p.dx = dir*rnd(0,1);
		p.dy = -rnd(0.5,1.5);
		p.gy = rnd(0.05,0.10);
		p.frict = rnd(0.8,0.92);
		p.lifeS = rnd(0.1,0.5);
		p.onUpdate = _dustPhysics;
	}

	public function aggro(e:Entity, c=0xffcc00) {
		// Exclamation
		var p = allocTopAdd( getTile(dict.fxExclamation), e.centerX, e.top - 4);
		p.colorize(c);
		p.setFadeS(1, 0, 0.2);
		p.lifeS = 0.7;
		p.dy = -2;
		p.frict = 0.8;

		// Lines
		var n = 8;
		var d = 4;
		for(i in 0...n) {
			var a = ( -0.15 - 0.7*i/(n-1) ) * M.PI;
			var p = allocTopAdd( getTile(dict.fxLineThinRight), e.centerX+Math.cos(a)*d, e.top+Math.sin(a)*d );
			p.colorize(c);
			p.scaleX = 0.5;
			p.alpha = 0.7;
			p.moveAng(a,3);
			p.frict = 0.7;
			p.rotation = a;
			p.scaleXMul = 0.9;
			p.lifeS = 0.2;
		}
	}


	public function sweat(e:Entity, c=0x5dcbf5) {
		var n = irnd(3,6);
		for(i in 0...n) {
			var d = irnd(1,3);
			var a = ( -0.15 - 0.7*i/(n-1) ) * M.PI - e.dir*0.3 + rnd(0,0.1,true);
			var p = allocTopAdd( getTile(dict.pixel), e.centerX+Math.cos(a)*d, e.top+Math.sin(a)*d );
			p.colorize(c);
			p.scaleX = irnd(1,3);
			p.alpha = 0.7;
			p.autoRotateSpeed = 1;
			p.moveAng(a,rnd(0.8,1.4));
			p.rotation = a;
			p.gy = rnd(0.02,0.06);
			p.frict = 0.9;
			// p.scaleXMul = 0.93;
			p.lifeS = 0.2;
		}
	}


	public function dodgeLand(x:Float, y:Float, dir:Int, col=0xcbb5a0) {
		for(i in 0...10) {
			var p = allocTopNormal( getTile(dict.pixel), x, y );
			p.setFadeS(rnd(0.4,0.7), 0.06, R.around(0.2));
			p.colorize(col);
			p.scaleX = irnd(2,3);
			p.autoRotateSpeed = 1;
			p.dx = dir*rnd(3,4);
			p.dy = -rnd(1.5, 2);
			p.gy = rnd(0.05,0.10);
			p.frict = R.around(0.85);
			p.lifeS = rnd(0.1,0.5);
			p.onUpdate = _dustPhysics;
		}
	}

	public function dodgeBrake(x:Float, y:Float, dir:Int, col=0xcbb5a0) {
		for(i in 0...2) {
			var p = allocTopNormal( getTile(dict.pixel), x, y );
			p.setFadeS(rnd(0.4,0.7), 0.06, R.around(0.2));
			p.colorize(col);
			p.dx = dir*rnd(3,4);
			p.dy = -rnd(0.7, 1);
			p.gy = rnd(0.05,0.10);
			p.frict = R.around(0.85);
			p.lifeS = rnd(0.1,0.5);
			p.onUpdate = _dustPhysics;
		}
	}

	public function ember(x:Float, y:Float) {
		var p = allocBgAdd( getTile(dict.pixel), x, y );
		p.colorAnimS(0xffcc00, 0x990000, rnd(0.4,1));
		p.setFadeS(rnd(0.4,1), R.around(0.1), R.around(0.3));
		p.gy = rnd(0.02, 0.05);
		p.frict = R.around(0.90);
		p.lifeS = rnd(0.1,0.5);
		p.onUpdate = _dustPhysics;
	}

	public function blackDust(x:Float, y:Float) {
		// Lines
		var p = allocBgNormal( getTile(dict.fxLineThinRight), x, y+rnd(0,2) );
		p.setCenterRatio(0.1,0.5);
		p.setFadeS(rnd(0.2,0.5), R.around(0.3), R.around(0.5));
		p.colorize(0x0);
		p.rotation = M.PIHALF;
		p.dsX = rnd(0.02,0.04);
		p.dsFrict = R.aroundZTO(0.995,5);
		p.scaleXMul = 0.985;
		p.scaleX = rnd(0.05,0.15);
		p.lifeS = rnd(0.4,0.8);
		p.delayS = R.around(0.2);

		// Dots
		for(i in 0...irnd(1,3)) {
			var p = allocBgNormal( getTile(dict.pixel), x+rnd(0,1,true), y );
			p.setFadeS(rnd(0.3,0.8), 0, R.around(0.2));
			p.colorize(0x0);
			p.gy = rnd(0.07,0.16);
			p.frict = rnd(0.90,0.96);
			p.lifeS = rnd(0.6,2);
			p.delayS = rnd(0,0.3);
			p.data0 = R.around(0.2);
			p.onUpdate = _dustPhysics;
		}
	}

	function _dirtPhysics(p:HParticle) {
		// Hand slowly at start
		if( p.data1>0 ) {
			p.data1 -= 1/Const.FPS * tmod;
			p.dy *= Math.pow(0.1,tmod);
		}

		if( collides(p) ) {
			if( p.data0!=1 ) {
				// First ground contact
				p.data0 = 1;
				p.setCenterRatio(0.5,1);
				p.dx = rnd(0.1,0.4,true);
				p.dy *= -0.3;
				p.gy *= 0.6;
				p.dr = 0;
				p.rotation = 0;
				p.scaleX *= 1.5;
				p.scaleY *= 0.5;
				p.scaleYMul = R.aroundZTO(0.99);
				p.y--;

				// Small particles when hitting ground
				for(i in 0...irnd(2,4)) {
					var d = allocBgNormal( getTile(dict.pixel), p.x+rnd(0,2,true), p.y-rnd(0,2) );
					d.colorize(0x0);
					d.setFadeS(rnd(0.7,1), 0, 0.1);
					d.moveAwayFrom(p.x,p.y, rnd(0.3,0.8));
					d.gy = R.around(0.03);
					d.frict = R.around(0.93);
					d.onUpdate = _dustPhysics;
					d.lifeS = R.around(0.2);
				}
			}
			else {
				p.dy *= Math.pow(0.6,tmod);
				p.gy *= Math.pow(0.6,tmod);
			}
		}
	}

	public function blackDirt(x:Float, y:Float) {
		var p = allocBgNormal( getTile(dict.fxDirt), x+rnd(0,1,true), y );
		p.setFadeS(rnd(0.8,1), 0.1, R.around(1));
		p.colorize(0x0);
		p.rotation = R.fullCircle();
		p.dr = rnd(0,0.1,true);
		p.randScale(0.4,1,true);
		p.gy = rnd(0.15,0.24);
		p.frict = rnd(0.92,0.96);
		p.lifeS = rnd(0.6,2);
		p.delayS = rnd(0,0.3);

		p.data1 = rnd(0.2,0.5);
		p.onUpdate = _dirtPhysics;
	}

	public function wreckTail(x:Float, y:Float) {
		// Dirt
		var p = allocBgNormal( getTile(dict.fxDirt), x+rnd(0,8,true), y+rnd(0,2,true) );
		p.setFadeS(rnd(0.7,0.9), 0.03, R.around(0.3));
		p.colorize(0x0);
		p.rotation = R.fullCircle();
		p.dr = rnd(0,0.1,true);
		p.randScale(0.6,1,true);
		p.gy = rnd(0.03,0.20);
		p.frict = rnd(0.92,0.96);
		p.lifeS = R.around(0.3);
		p.onUpdate = _dirtPhysics;

		// Fire
		for(i in 0...3) {
			var p = allocTopAdd( getTile(dict.fxFlame), x+rnd(0,4,true), y+rnd(-10,4) );
			p.setFadeS( rnd(0.7,1), R.around(0.06), R.around(0.2) );
			p.colorAnimS(R.colorMix(0xff0000,0xffcc00), 0x585881, rnd(0.2,0.4));
			p.scaleX = rnd(0.3,0.6,true);
			p.scaleY = rnd(0.5,1);
			p.scaleMul = R.aroundBO(0.96);
			p.dy = -rnd(0.5,1);
			p.frict = R.aroundBO(0.95);
			p.lifeS = R.around(0.2);
		}
	}




	function _brickPhysics(p:HParticle) {
		if( collides(p) ) {
			p.rotation = 0;
			if( p.data0!=1 ) {
				// First ground contact
				p.data0 = 1;
				p.setCenterRatio(0.5,1);
				p.dx = rnd(0.1,0.4,true);
				p.dy *= -rnd(0.3,0.5);
				p.gy *= 0.8;
				p.y-=irnd(2,3);
			}
			else {
				// Stuck to ground
				p.dr = 0;
				p.dx *= Math.pow(0.7,tmod);
				p.dy = 0;
				p.gy = 0;
			}
		}
		else if( p.data0==1 ) {
			// Restart falling
			p.gy = 0.2;
		}
	}


	public function groundExplosion(cx:Int,cy:Int, c1:UInt, c2:UInt) {
		var x = cx*Const.GRID;
		var y = cy*Const.GRID;
		var centerX = (cx+0.5)*Const.GRID;
		var centerX = (cx+0.5)*Const.GRID;

		// Main bricks
		var n = 10;
		for(i in 0...n) {
			var p = allocBgNormal(getTile(dict.fxBrick), x+rnd(0.1,.9)*Const.GRID, y+rnd(0.1,0.9)*Const.GRID);
			p.setFadeS(1, 0.1, rnd(1,3));
			p.colorizeRandom(c1,c2);
			p.scaleX = rnd(0.7,1.2);
			p.dx = rnd(0,1,true);
			p.dy = -rnd(1,4);
			p.dr = rnd(0.02,0.10,true);
			p.rotation = rnd(0,0.3,true);
			p.gy = rnd(0.12,0.20);
			p.frict = R.aroundBO(0.96);
			p.lifeS = rnd(4,7);

			p.onUpdate = _brickPhysics;
		}

		// Delayed falling bricks
		n = 20;
		for(i in 0...n) {
			var p = allocBgNormal(getTile(dict.fxBrick), x+rnd(0.1,.9)*Const.GRID, y+rnd(0.1,0.9)*Const.GRID);
			p.setFadeS(1, 0.1, rnd(1,3));
			p.colorizeRandom(c1,c2);
			p.scaleX = rnd(0.7,1.2);
			p.dx = rnd(0,1,true);
			p.dr = rnd(0.02,0.10,true);
			p.rotation = rnd(0,0.3,true);
			p.gy = rnd(0.12,0.20);
			p.frict = R.aroundBO(0.96);
			p.lifeS = rnd(4,7);
			p.delayS = rnd(0.2,0.6);

			p.onUpdate = _brickPhysics;
		}

		// Dust
		n = 40;
		for(i in 0...n) {
			var p = allocBgNormal(getTile(dict.pixel), x+rnd(0.1,.9)*Const.GRID, y+rnd(0.1,0.9)*Const.GRID);
			p.setFadeS(1, 0, R.around(0.5));
			p.colorizeRandom(c1,c2);
			p.scaleX = rnd(0.7,1.2);
			p.gy = rnd(0.06,0.15);
			p.frict = R.aroundBO(0.92);
			p.lifeS = rnd(1,3);
			p.delayS = rnd(0.3, 2.5);

			p.onUpdate = _dustPhysics;
		}
	}


	public function grassExplosion(cx:Int,cy:Int, c1:UInt, c2:UInt) {
		var x = cx*Const.GRID;
		var y = cy*Const.GRID;
		var centerX = (cx+0.5)*Const.GRID;
		var centerX = (cx+0.5)*Const.GRID;

		// Main grass
		var n = 10;
		for(i in 0...n) {
			var p = allocBgNormal(getTile(dict.fxDirt), x+rnd(0.1,.9)*Const.GRID, y+rnd(0.1,0.9)*Const.GRID);
			p.setFadeS(1, 0.1, rnd(1,3));
			p.colorizeRandom(c1,c2);
			p.scaleX = rnd(0.7,1.2);
			p.dx = rnd(0,1,true);
			p.dy = -rnd(1,4);
			p.dr = rnd(0.02,0.10,true);
			p.rotation = rnd(0,0.3,true);
			p.gy = rnd(0.12,0.20);
			p.frict = R.aroundBO(0.96);
			p.lifeS = rnd(4,7);

			p.onUpdate = _brickPhysics;
		}

		// Delayed falling grass
		n = 20;
		for(i in 0...n) {
			var p = allocBgNormal(getTile(dict.fxDirt), x+rnd(0.1,.9)*Const.GRID, y+rnd(0.1,0.9)*Const.GRID);
			p.setFadeS(1, 0.1, rnd(1,3));
			p.colorizeRandom(c1,c2);
			p.scaleX = rnd(0.7,1.2);
			p.dx = rnd(0,1,true);
			p.dr = rnd(0.02,0.10,true);
			p.rotation = rnd(0,0.3,true);
			p.gy = rnd(0.12,0.20);
			p.frict = R.aroundBO(0.96);
			p.lifeS = rnd(4,7);
			p.delayS = rnd(0.2,0.6);

			p.onUpdate = _brickPhysics;
		}

		// Dust
		n = 40;
		for(i in 0...n) {
			var p = allocBgNormal(getTile(dict.pixel), x+rnd(0.1,.9)*Const.GRID, y+rnd(0.1,0.9)*Const.GRID);
			p.setFadeS(1, 0, R.around(0.5));
			p.colorizeRandom(c1,c2);
			p.scaleX = rnd(0.7,1.2);
			p.gy = rnd(0.06,0.15);
			p.frict = R.aroundBO(0.92);
			p.lifeS = rnd(1,3);
			p.delayS = rnd(0.3, 2.5);

			p.onUpdate = _dustPhysics;
		}
	}


	public function wreckExplosion(x:Float, y:Float) {
		// Explosion anims
		for(i in 0...irnd(3,5)) {
			var d = i<=1 ? rnd(0,2) : rnd(3,8);
			var a = R.fullCircle();
			var p = allocBgAdd(getTile(dict.fxExplode), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.playAnimAndKill( Assets.tiles, dict.fxExplode, rnd(0.6,0.8) );
			p.setScale(rnd(0.6,0.7));
			p.rotation = R.fullCircle();
			p.delayS = i*0.02 + rnd(0, 0.03, true);
		}

		// Small lines
		var n = 30;
		for(i in 0...n) {
			var a = M.PI2*i/(n-1) + rnd(0,0.2,true);
			var d = rnd(2,5);
			var p = allocTopAdd(getTile(dict.fxLineThinLeft), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorizeRandom(0xff0000, 0xffcc00);
			p.scaleX = R.around(0.3);
			p.scaleXMul = R.aroundZTO(0.91);
			p.moveAwayFrom(x,y, rnd(5,9));
			p.frict = R.aroundZTO(0.75);
			p.rotation = a;
			p.lifeS = R.around(0.2);
			p.delayS = rnd(0,0.1);
		}

		// Flames lines
		var n = 20;
		for(i in 0...n) {
			var a = M.PI2*i/(n-1) + rnd(0,0.2,true);
			var d = rnd(2,5);
			var p = allocTopAdd(getTile(dict.fxFlame), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorizeRandom(0xff0000, 0xff8800);
			p.scaleX = R.around(0.9,true);
			p.scaleY = R.around(0.6);
			p.scaleYMul = R.aroundZTO(0.95);
			p.gy = rnd(0,0.1);
			p.moveAwayFrom(x,y, rnd(3,5));
			p.frict = R.aroundZTO(0.75);
			p.rotation = a+M.PIHALF;
			p.lifeS = R.around(0.2);
			p.delayS = rnd(0,0.1);
		}
	}



	public function mobDeath(x:Float, y:Float) {
		flashBangS(0xffcc00, 0.2, 1);
		// Small lines
		var n = 40;
		for(i in 0...n) {
			var a = M.PI2*i/(n-1) + rnd(0,0.2,true);
			var d = rnd(2,5);
			var p = allocTopAdd(getTile(dict.fxLineThinLeft), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorizeRandom(0xff0000, 0xffcc00);
			p.scaleX = R.around(0.3);
			p.scaleXMul = R.aroundZTO(0.91);
			p.moveAwayFrom(x,y, rnd(5,9));
			p.frict = R.aroundZTO(0.75);
			p.rotation = a;
			p.lifeS = R.around(0.4);
			p.delayS = rnd(0,0.1);
		}

		// Flames lines
		var n = 20;
		for(i in 0...n) {
			var a = M.PI2*i/(n-1) + rnd(0,0.2,true);
			var d = rnd(2,5);
			var p = allocTopAdd(getTile(dict.fxFlame), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorizeRandom(0xff0000, 0xff8800);
			p.scaleX = R.around(0.9,true);
			p.scaleY = R.around(0.6);
			p.scaleYMul = R.aroundZTO(0.95);
			p.gy = rnd(0,0.1);
			p.moveAwayFrom(x,y, rnd(3,5));
			p.frict = R.aroundZTO(0.75);
			p.rotation = a+M.PIHALF;
			p.lifeS = R.around(0.4);
			p.delayS = rnd(0,0.1);
		}

		// Gibs
		var n = 30;
		for(i in 0...n) {
			var p = allocTopAdd(getTile(dict.fxDirt), x+rnd(0,5,true), y+rnd(0,8,true));
			p.setFadeS(R.around(0.9), 0, rnd(2,3));
			p.colorAnimS(0xff8800, 0x990000, rnd(0.6,2));
			p.gy = rnd(0.02,0.05);
			p.dr = rnd(0.01,0.03,true);
			p.scaleX = rnd(0.8,1,true);
			p.scaleY = rnd(0.8,1,true);
			p.scaleMul = R.aroundBO(0.97);
			p.rotation = R.fullCircle();
			p.moveAwayFrom(x,y, rnd(0.4,1));
			p.frict = R.aroundZTO(0.85);
			p.lifeS = R.around(5);
			p.onUpdate = _dirtPhysics;
		}

		// Dust
		var n = 50;
		for(i in 0...n) {
			var p = allocTopAdd(getTile(dict.pixel), x+rnd(0,5,true), y+rnd(0,8,true));
			p.setFadeS(R.around(0.9), 0, rnd(2,3));
			p.colorizeRandom(0xff0000, 0xff8800);
			p.alphaFlicker = 0.4;
			p.gy = rnd(0.005,0.012);
			p.moveAwayFrom(x,y, rnd(0.4,1));
			p.frict = R.aroundZTO(0.85);
			p.lifeS = R.around(2);
			p.onUpdate = _dustPhysics;
		}
	}


	public function wreckAnnounce(x:Float, y:Float, ratio:Float) {
		// Line
		var p = allocBgAdd( getTile(dict.fxLineThinRight), x, y );
		p.setCenterRatio(0,0.5);
		p.setFadeS(0.6*ratio, 0, 0.06);
		p.colorize(0xff0000);
		p.scaleY = 3*ratio;
		p.rotation = M.PIHALF;
		var cx = Std.int(x/Const.GRID);
		var cy = Std.int(y/Const.GRID)+1;
		while( !level.hasAnyCollision(cx,cy) )
			cy++;
		p.scaleX = ( (cy+0.5)*Const.GRID - y ) / p.t.width;

		// Dirt
		var p = allocBgNormal( getTile(dict.fxDirt), x+rnd(0,8,true), y );
		p.setFadeS(rnd(0.8,1), 0.1, R.around(1));
		p.colorize(0x0);
		p.rotation = R.fullCircle();
		p.dr = rnd(0,0.1,true);
		p.randScale(0.4,1,true);
		p.gy = rnd(0.2,0.3);
		p.frict = rnd(0.92,0.96);
		p.lifeS = rnd(0.6,2);
		p.delayS = rnd(0,0.1);
		p.onUpdate = _dirtPhysics;

		// Dust
		var p = allocBgNormal( getTile(dict.pixel), x+rnd(0,8,true), y );
		p.setFadeS(rnd(0.7,1), 0, R.around(0.2));
		p.colorize(0x0);
		p.gy = rnd(0.2,0.3);
		p.frict = rnd(0.90,0.96);
		p.lifeS = rnd(0.6,2);
		p.data0 = R.around(0.2);
		p.onUpdate = _dustPhysics;
	}


	function _bubbleDistort(p:HParticle) {
		if( Math.isNaN(p.data0) ) {
			p.data1 = rnd(0.07,0.10); // speed
			p.data0 = R.fullCircle(); // rad offset
		}

		p.scaleX = 1+Math.cos(ftime*p.data1 + p.data0)*0.2;
		p.scaleY = 1/p.scaleX;
	}

	function _bubblePop(b:HParticle) {
		var p = allocBgAdd(getTile(dict.fxBubblePop), b.x, b.y);
		p.setCenterRatio(0.5,1);
		p.colorize(b.userData);
		p.setFadeS( rnd(0.4,0.6), 0, 0.1 );
		p.dsX = rnd(0.01,0.05);
		p.dsY = rnd(0.01,0.05);
		p.dsFrict = R.around(0.9, 5);
		p.lifeS = R.around(0.1);
	}


	public inline function largeBubbles(x:Float,y:Float, bounds:h2d.col.Bounds, col=0x4d4959) {
		var p = allocTopAdd( getTile(dict.fxBubble), x+rnd(0,8,true), y+rnd(0,8,true) );
		p.colorize(col);
		p.setFadeS( rnd(0.1, 0.3), rnd(0.6,1), rnd(1,2) );
		p.gx = R.around(0.005);
		p.gy = -rnd(0.001, 0.020);
		p.frict = rnd(0.97,0.98);
		p.lifeS = rnd(1,2);
		p.delayS = rnd(0,0.4);
		p.bounds = bounds;
		p.userData = col;
		p.onKillP = _bubblePop;
		p.onUpdate = _bubbleDistort;
	}


	public inline function tinyBubbles(x:Float,y:Float, bounds:h2d.col.Bounds, col=0x4d4959) {
		var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,8,true), y+rnd(0,8,true) );
		p.colorize(col);
		p.setFadeS( rnd(0.2, 0.6), rnd(0.2,0.4), rnd(0.2,0.4) );
		p.alphaFlicker = rnd(0,0.1);
		p.gx = R.around(0.005);
		p.gy = -rnd(0.001, 0.020);
		p.frict = rnd(0.97,0.98);
		p.lifeS = rnd(0.3,0.6);
		p.delayS = rnd(0,0.4);
		p.bounds = bounds;
	}


	final waveSpeed = 0.06;
	inline function getWaveOffY(x:Float) {
		return 2 * Math.cos(ftime*waveSpeed + x*0.03);
	}
	inline function getWaveAng(x:Float) {
		return 0.2 * Math.cos(ftime*waveSpeed + x*0.03 + M.PIHALF);
	}

	public inline function waterSurfaceDark(x:Float,y:Float, col=0x4d4959) {
		var p = allocBgNormal( getTile(dict.fxWaterSurfaceMask), x+rnd(0,4,true), y-rnd(0,2)+getWaveOffY(x) );
		p.setCenterRatio(0.5, 0);
		p.colorize( C.toBlack(col,rnd(0.6,0.9)) );
		p.setFadeS( rnd(0.6, 0.9), rnd(0.6,1), rnd(1,2) );
		p.scaleX = R.sign();
		p.dx = rnd(0,0.3,true);
		p.dy = rnd(0,0.1);
		p.frict = rnd(0.97,0.98);
		p.lifeS = rnd(0.4,0.7);
		p.delayS = rnd(0,0.3);
	}


	public inline function waterSurfaceRipples(x:Float,y:Float, col=0x4d4959) {
		var p = allocTopAdd( getTile(dict.fxWaterSurface), x+rnd(0,4,true), y+rnd(0,1)+getWaveOffY(x) );
		p.colorize(col);
		p.setFadeS( rnd(0.8, 0.9), rnd(0.2,0.4), R.around(0.2) );
		p.scaleX = rnd(0.8,1.2,true);
		p.scaleXMul = rnd(0.993, 0.995);
		p.dx = rnd(0,0.3,true);
		p.dy = rnd(0,0.06);
		// p.gy = R.around(0.002,3);
		p.frict = rnd(0.97,0.98);
		p.rotation = getWaveAng(x);
		p.lifeS = rnd(0.3,0.6);
		p.delayS = rnd(0,0.2);
	}


	public inline function waterSplashes(x:Float,y:Float, pow:Float, col=0x4d4959) {
		// Waves
		for(i in 0...2) {
			var p = allocTopAdd( getTile(dict.fxWaterSurface), x+rnd(0,3,true), y+rnd(0,1,true)+getWaveOffY(x) );
			p.colorize(C.toWhite(col,rnd(0.2,0.4)));
			p.setFadeS( rnd(0.8, 1)*pow, 0.2, R.around(0.2) );
			p.scaleX = rnd(0.8,1.2,true);
			p.scaleXMul = rnd(0.993, 0.995);
			p.scaleY = rnd(1.5,2);
			p.scaleYMul = rnd(0.98,0.99);
			p.dx = rnd(0.1,0.2) * M.sign(p.x-x);
			p.dy = -rnd(0,0.06)*pow;
			p.gy = R.around(0.03);
			p.groundY = y+3;
			p.bounceMul = 0;
			p.frict = R.aroundBO(0.98);
			p.rotation = getWaveAng(x);
			p.lifeS = rnd(0.3,0.6);
			p.delayS = rnd(0,0.2);
		}
		// Dots
		for(i in 0...irnd(2,4)) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(2,7,true), y-rnd(1,5)+getWaveOffY(x) );
			p.colorize(C.toWhite(col,0.4));
			p.setFadeS( rnd(0.6, 0.9)*pow, 0.06, R.around(0.2) );
			p.dx = rnd(0,0.2) * M.sign(p.x-x)*pow;
			p.dy = -rnd(0.5,1)*pow;
			p.gy = R.around(0.06);
			p.groundY = y+3;
			p.bounceMul = 0;
			p.frict = R.aroundBO(0.92);
			p.lifeS = rnd(0.1,0.3);
		}
	}

	public function enterWater(x:Float, y:Float, col:Int, pow=1.0) {
		// Hit lines
		final n = Std.int(pow*30);
		var range = M.PI*0.6;
		for(i in 0...n) {
			var pow = 0.55 + 0.45*Math.sin( M.PI * i/(n-1) );
			var a = -M.PIHALF - range*0.5 + range*i/(n-1) + rnd(0,0.15,true);
			var p = allocBgAdd( getTile(dict.fxLineThinRight), x+Math.cos(a)*4, y+Math.sin(a)*4 );
			p.alpha = R.around(0.2)*pow;
			p.colorize(col);
			p.setCenterRatio(0, 0.5);
			p.scaleX = rnd(0.1,0.2) * pow;
			p.dsX = rnd(0.45,0.50) * pow;
			p.dsFrict = 0.92;
			p.scaleXMul = R.around(0.8,5);
			p.rotation = a;
			p.lifeS = R.around(0.2);
		}

		// Main splashes
		final n = Std.int(pow*70);
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxLine), x+rnd(0,6,true), y-rnd(1,2) );
			p.setFadeS( rnd(0.5,0.9), 0, rnd(0.1,0.3));
			p.colorize( C.toWhite(col, rnd(0.3,0.7)) );
			p.scaleX = rnd(0.1,0.3, true);
			p.scaleXMul = rnd(0.96,0.97);
			p.dx = rnd(0.2,1,true);
			p.dy = -rnd(0.5, 2);
			if( i<=3 )
				p.dy*=rnd(1.5,2);
			p.gy = rnd(0.06,0.10);
			p.frict = R.around(0.97,3);
			p.autoRotate();
			p.groundY = y;
			p.bounceMul = 0;
			p.drFrict = R.around(0.95);
			p.rotation = R.fullCircle();
			p.lifeS = rnd(0.4,0.9);
			p.onUpdate = _dirtPhysics;
		}
		// Falling drips
		final n = Std.int(pow*20);
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,10,true), y-rnd(10,30) );
			p.setFadeS( rnd(0.4,1), R.around(0.2), R.around(1));
			p.colorize(col);
			p.gy = rnd(0.01,0.08);
			p.groundY = y+rnd(0,2);
			p.bounceMul = 0;
			p.frict = R.around(0.92,10);
			p.lifeS = rnd(1,3);
			p.onUpdate = _dustPhysics;
			p.delayS = rnd(0,1);
		}
	}


	public function leaveWater(x:Float, y:Float, dir:Int, col:Int) {
		// Main splashes
		final n = 70;
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxLine), x+rnd(0,6,true), y-rnd(1,2) );
			p.setFadeS( rnd(0.5,0.9), 0, rnd(0.1,0.3));
			p.colorize( C.toWhite(col, rnd(0.3,0.7)) );
			p.scaleX = rnd(0.1,0.2, true);
			p.scaleXMul = rnd(0.96,0.97);
			p.dx = rnd(0,0.4)*dir;
			p.dy = -rnd(0.7, 2.5);
			if( i<=6 )
				p.dy*=rnd(1.2,1.6);
			p.gy = rnd(0.06,0.12);
			p.frict = R.around(0.97,3);
			p.autoRotate();
			p.groundY = y;
			p.bounceMul = 0;
			p.drFrict = R.around(0.95);
			p.rotation = R.fullCircle();
			p.lifeS = rnd(0.4,0.9);
			p.onUpdate = _dirtPhysics;
		}

		// Falling drips
		final n = 20;
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,10,true), y-rnd(10,30) );
			p.setFadeS( rnd(0.4,1), R.around(0.2), R.around(1));
			p.colorize(col);
			p.gy = rnd(0.01,0.08);
			p.groundY = y+rnd(0,2);
			p.bounceMul = 0;
			p.frict = R.around(0.92,10);
			p.lifeS = rnd(1,3);
			p.onUpdate = _dustPhysics;
			p.delayS = rnd(0,1);
		}
	}


	public inline function waterSideDrips(x:Float,y:Float, dir:Int, col=0x4d4959) {
		var delay = rnd(0.1,0.3);
		var waveOffY = getWaveOffY(x);

		var p = allocTopAdd( getTile(dict.fxWaterSurfaceSide), x+rnd(0,2,true), y+rnd(0,2,true)+waveOffY );
		p.setCenterRatio(0,0.5);
		p.colorize(col);
		p.setFadeS( rnd(0.4, 0.6), R.around(0.05), R.around(0.2) );
		p.rotation = rnd(0,0.1,true);
		p.scaleX = rnd(0.3,1.6) * dir;
		p.scaleXMul = rnd(0.98,0.99);
		p.scaleY = rnd(0.5,1);
		p.lifeS = rnd(0.2,0.4);
		p.delayS = delay*0.5;

		if( Std.random(100)<30 )
			for( i in 0...irnd(1,4)) {
				var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,2,true), y+rnd(0,2,true)+waveOffY );
				p.colorize(col);
				p.setFadeS( rnd(0.4, 0.6), R.around(0.1), R.around(0.1) );
				p.dx = dir*rnd(0,0.5);
				p.dy = -rnd(0.3, 1);
				p.gy = R.around(0.04,3);
				p.groundY = y+rnd(1,3);
				p.frict = rnd(0.97,0.98);
				p.lifeS = rnd(0.2,0.4);
				p.delayS = delay+rnd(0,0.2);
			}
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
		else if( fs.magic ) {
			baseCol = 0x1eff98;
			finalCol = 0x659ab5;
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

	public function upgradeHalo(x:Float, y:Float) {
		for(i in 0...4) {
			var a = R.fullCircle();
			var p = allocTopAdd( getTile(dict.fxLineThinLeft), x,y );
			p.setFadeS( R.around(0.5), 0.3, 0.4 );
			p.colorize(0xff8800);
			p.setCenterRatio(1.3, 0.5);

			p.rotation = a+M.PI;
			p.scaleX = R.around(0.2);
			p.dr = R.zeroTo(0.01,true);
			p.dsX = R.around(0.1);
			p.dsFrict = R.aroundZTO(0.76);
			p.scaleXMul = rnd(0.985,0.999);
			p.lifeS = R.around(0.4);

		}
	}

	public inline function lightSmoke(x:Float,y:Float, c:UInt) {
		var p = allocBgAdd( getTile(dict.fxSmoke), x+rnd(8,20,true), y+rnd(8,20,true) );
		p.setFadeS(R.around(0.1), rnd(0.4,0.6), rnd(0.8,1));
		p.colorize(c);
		p.setScale(rnd(1,2,true));
		p.rotation = rnd(0,M.PI2);
		p.dr = rnd(0,0.02,true);
		p.ds = rnd(0.002, 0.004);
		p.gx = R.around(0.010);
		p.gy = R.around(0.015);
		p.frict = R.aroundZTO(0.94);
		p.lifeS = rnd(0.3,0.6);
	}

	public inline function lightFlare(x:Float,y:Float, c:UInt, intensity=1.0) {
		var p = allocTopAdd( getTile(dict.fxFlare), x, y );
		p.setFadeS(R.around(0.2)*intensity, 0.2, R.around(0.5));
		p.colorize(c);
		p.scaleX = intensity * R.around(0.7) * ( 0.8 + 0.2*Math.cos(ftime*0.4) );
		p.lifeS = R.around(0.2);
	}


	public function waterShoot(x:Float, y:Float, ang:Float) {
		for(i in 0...3) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,2,true), y+rnd(0,2,true));
			p.setFadeS(rnd(0.6,0.9), 0.03, R.around(0.1));
			p.moveAng( ang + rnd(0.2, 1.3, true), R.around(0.7));
			p.frict = R.aroundZTO(0.8);
			p.colorize(Const.WATER_COLOR);
			p.lifeS = R.around(0.07);
		}

		for(i in 0...4) {
			var p = allocTopAdd( getTile(dict.fxLineThinLeft), x, y);
			p.setFadeS(R.aroundZTO(0.7), 0.03, R.around(0.1));
			p.scaleX = R.around(0.25);
			p.scaleY = rnd(1,2);
			p.moveAng( ang + rnd(0.1, 0.6, true), R.around(2));
			p.scaleXMul = R.aroundZTO(0.97);
			p.autoRotateSpeed = 1;
			p.frict = R.aroundZTO(0.8);
			p.colorize(Const.WATER_COLOR);
			p.lifeS = R.around(0.07);
		}
	}


	public function tail(e:Entity, c:Int) {
		var d = M.dist(e.centerX, e.centerY, e.lastTailX, e.lastTailY);
		if( e.lastTailX>=0 && d>=2 ) {
			var a = Math.atan2(e.lastTailY-e.centerY, e.lastTailX-e.centerX);

			var p = allocBgAdd(getTile(dict.fxTail), e.centerX, e.centerY);
			p.setCenterRatio(0.1,0.5);
			p.setFadeS(0.3, 0.1, 0.5);
			p.rotation = a;
			p.scaleX = (d+2)/p.t.width;
			p.colorize(c);
			p.lifeS = 0.2;
		}

		if( d>=2 ) {
			e.lastTailX = e.centerX;
			e.lastTailY = e.centerY;
		}
	}


	public function waterTail(lastX:Float, lastY:Float, curX:Float, curY:Float, elapsed:Float, col:UInt) {
		var alpha = compressUp( 1 - elapsed, 0.8 );
		var d = M.dist(curX, curY, lastX, lastY);
		var a = Math.atan2(curY-lastY, curX-lastX);

		// Tail core
		var p = allocTopAdd( getTile(dict.fxWaterTail), lastX, lastY);
		p.setFadeS(R.aroundZTO(0.4)*alpha, 0, 0.1);
		p.colorize(col);
		p.setCenterRatio(0.2,0.5);
		p.rotation = a;
		p.scaleX = (d+17)/p.t.width;
		p.scaleY = R.aroundZTO(0.7);
		p.scaleYMul = R.aroundZTO(0.96);
		p.lifeS = R.around(0.2);

		// Dots
		var off = rnd(0.5,2,true);
		var p = allocTopAdd( getTile(dict.pixel), (lastX+curX)*0.5 + Math.cos(a+M.PIHALF)*off, (lastY+curY)*0.5+Math.sin(a+M.PIHALF)*off);
		p.setFadeS( R.aroundZTO(0.7)*alpha, 0, 0.1);
		p.colorize(col);
		p.moveAng(a, rnd(1,3));
		p.frict = R.aroundZTO(0.8);
		p.gy = rnd(0.1,0.2);
		p.onUpdate = _waterPhysics;
		p.lifeS = rnd(0.06,0.10);

		// Line
		var offX = rnd(0,5,true);
		var offY = rnd(0.5,2,true);
		var p = allocTopAdd(
			getTile(dict.fxLineThinLeft),
			(lastX+curX)*0.5 + Math.cos(a+M.PIHALF)*offY + Math.cos(a)*offX,
			(lastY+curY)*0.5+Math.sin(a+M.PIHALF)*offY + Math.sin(a)*offX
		);
		p.setFadeS( R.around(0.4)*alpha, 0, 0.1);
		p.colorize(col);
		p.rotation = a;
		p.scaleX = d / p.t.width;
		p.scaleMul = rnd(1.02,1.03);
		p.frict = R.aroundZTO(0.8);
		p.lifeS = rnd(0.06,0.10);
	}

	function _waterPhysics(p:HParticle) {
		if( p.data0!=1 && collides(p) ) {
			p.data0 = 1;
			p.dx = p.dy = 0;
			p.gy = 0;
			p.autoRotateSpeed = 0;
			p.setScale( rnd(2,3) );
			p.scaleMul = R.aroundZTO(0.96);
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
			p.frict = R.aroundZTO(0.9);
			p.colorize(Const.WATER_COLOR);
			p.onUpdate = _waterPhysics;
			p.lifeS = rnd(0.1,0.3);
		}
	}

	public function sprinklerStart(x:Float, y:Float, ang:Float) {
		for(i in 0...Std.int(R.around(50))) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,3,true), y+rnd(0,3,true) );
			p.setFadeS(R.around(0.7), 0, 0.1);
			p.moveAng(ang + rnd(0,M.PIHALF*0.35,true), rnd(0,3));
			p.gy = R.around(0.1,10);
			p.frict = R.aroundZTO(0.96);
			p.colorize(Const.WATER_COLOR);
			p.onUpdate = _waterPhysics;
			p.lifeS = R.around(1);
		}
	}


	public function triggerTarget(x:Float, y:Float) {
		var n = 20;
		var d = 8;
		for(i in 0...n) {
			var a = M.PI2 * i/n;
			var p = allocTopAdd( getTile(dict.fxLightning), x+Math.cos(a)*d, y+Math.sin(a)*d );
			p.setFadeS(R.around(0.7), 0, R.around(0.2));
			p.colorAnimS(0xffcc00, 0x244aed, 1);
			p.scaleY = rnd(0.5,1);
			p.rotation = a+M.PIHALF;
			p.moveAwayFrom(x,y, R.around(3));
			p.frict = 0.82;
			p.lifeS = R.around(0.4);
		}
	}

	public function triggerWire(fx:Float, fy:Float, tx:Float, ty:Float, durationS:Float, col=0x1ec8ff) {
		var d = M.dist(fx,fy, tx,ty);
		var a = Math.atan2( ty-fy, tx-fx );
		var n = M.round(d/16);
		var step = d/n;
		var lastX = fx;
		var lastY = fy;
		for(i in 1...n) {
			var x = fx+Math.cos(a)*d*i/(n-1) + rnd(0,8,true);
			var y = fy+Math.sin(a)*d*i/(n-1) + rnd(0,8,true);
			var p = allocTopAdd( getTile(dict.fxLightning), x, y );
			p.setCenterRatio(0, 0.5);
			p.setFadeS(R.around(0.8), 0, R.around(0.1));
			p.alphaFlicker = rnd(0.2,0.3);
			p.colorize(col);
			p.rotation = Math.atan2(lastY-y, lastX-x);
			p.scaleX = M.dist(lastX,lastY,x,y) / p.t.width;
			p.scaleY = rnd(1, 1.5, true);
			p.frict = R.around(0.95);
			p.delayS = i/(n-1) * durationS;
			p.lifeS = R.around(0.3);
			lastX = x;
			lastY = y;
		}
	}

	public function sprinkler(x:Float, y:Float) {
		for(i in 0...irnd(5,8)) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,3,true), y+rnd(0,3,true) );
			p.setFadeS(rnd(0.3,0.4), 0, 0.1);
			p.moveAwayFrom(x,y, rnd(1,2));
			p.gy = rnd(0.04,0.10);
			p.frict = R.aroundZTO(0.9);
			p.colorize(Const.WATER_COLOR);
			p.onUpdate = _waterPhysics;
			p.lifeS = rnd(0.1,0.3);
		}
	}

	public function waterVanish(x:Float, y:Float) {
		for(i in 0...2) {
			var p = allocTopAdd( getTile(dict.fxSmoke), x+rnd(0,3,true), y+rnd(0,3,true));
			p.setFadeS( R.aroundZTO(0.1), 0.1, 0.2);
			p.colorize(Const.WATER_COLOR);
			p.rotation = rnd(0,M.PI2);
			p.setScale(R.aroundZTO(0.6));
			p.dr = rnd(0.01,0.02,true);
			p.dy = -R.aroundZTO(0.5);
			p.lifeS = 0.2;
		}
	}

	public function fireSplash(x:Float, y:Float) {
		var p = allocTopAdd( getTile(dict.fxSmoke), x,y);
		p.setFadeS( R.aroundZTO(0.1), 0, 0.1);
		p.colorize(Const.WATER_COLOR);
		p.rotation = rnd(0,M.PI2);
		p.setScale(R.aroundZTO(0.8));
		p.lifeS = 0.1;

		for(i in 0...irnd(8,10)) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,3,true), y+rnd(0,3,true) );
			p.setFadeS(rnd(0.7,1), 0, 0.1);
			p.moveAwayFrom(x,y, rnd(1,2));
			p.gy = rnd(0.04,0.10);
			p.frict = R.aroundZTO(0.9);
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
			p.setFadeS( R.aroundZTO(0.9), 0, 0.1);
			p.colorize(0xff0000);
			p.dx = rnd(0,1,true);
			p.gy = R.around(0.05);
			p.dy = -R.around(0.5);
			p.frict = rnd(0.85,0.95);
			p.lifeS = R.around(0.3);
			p.delayS = i*0.05 + R.zeroTo(0.1,true);
		}
		// for(i in 0...12) {
		// 	var p = allocTopAdd(getTile(dict.fxStar), getFlameX(cx,cy)+rnd(0,4,true), getFlameY(cx,cy)+rnd(0,4,true)-8);
		// 	p.colorize(0x7860e7);
		// 	p.setScale(rnd(0.5,1));
		// 	p.dr = R.around(0.4) * rndSign();
		// 	p.dy = -R.around(2);
		// 	p.frict = rnd(0.75,0.85);
		// 	p.rotation = rnd(0, M.PI,true);
		// 	p.delayS = i * rnd(0,0.1);
		// 	p.lifeS = rnd(0.1,0.2);
		// }
	}


	public function explosion(x:Float,y:Float) {
		var r = Const.GRID*3;
		for(i in 0...16) {
			var d = i<=2 ? rnd(0,20) : rnd(0,r-10);
			var a = rnd(0,M.PI2);
			var p = allocBgAdd(getTile(dict.fxExplode), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.playAnimAndKill( Assets.tiles, dict.fxExplode, rnd(0.6,0.8) );
			p.setScale(rnd(0.9,1.5));
			p.rotation = rnd(0, 0.4, true);
			p.delayS = i*0.02 + rnd(0,0.1,true);
		}

		// Small lines
		var n = 70;
		for(i in 0...n) {
			var a = M.PI2*i/(n-1) + rnd(0,0.2,true);
			var d = rnd(20,r*0.5);
			var p = allocTopAdd(getTile(dict.fxLineThinLeft), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorizeRandom(0xff0000, 0xffcc00);
			p.scaleX = R.around(1);
			p.scaleY = rnd(1,2);
			p.scaleXMul = R.aroundZTO(0.94);
			p.moveAwayFrom(x,y, rnd(8,10));
			p.frict = R.aroundZTO(0.8);
			p.rotation = a;
			p.lifeS = R.around(0.2);
			p.delayS = rnd(0,0.1);
		}
	}


	public function irGate(fx:Float, fy:Float, tx:Float, ty:Float, c:Int) {
		var a = Math.atan2(ty-fy, tx-fx);
		var d = M.dist(fx,fy,tx,ty);
		for(i in 0...3) {
			var d = rnd(0.1,0.9) * d;
			var p = allocTopAdd( getTile(dict.fxLine), fx+Math.cos(a)*d, fy+Math.sin(a)*d );
			p.setFadeS(rnd(0.1,0.5), 0.1, 0.2);
			p.colorize(c);
			p.scaleX = R.around(0.1,true);
			p.moveAng(a, rnd(0,0.1,true));
			p.frict = R.around(0.85);
			p.rotation = a;
			p.lifeS = R.around(0.2);
		}
	}


	public function irGateTrigger(fx:Float, fy:Float, tx:Float, ty:Float, c:Int) {
		var a = Math.atan2(ty-fy, tx-fx);
		var d = M.dist(fx,fy,tx,ty);

		// Dots
		for(i in 0...40) {
			var dr = rnd(0,1);
			var p = allocTopAdd( getTile(dict.pixel), fx+Math.cos(a)*dr*d, fy+Math.sin(a)*dr*d );
			p.alphaFlicker = 0.3;
			p.setFadeS(rnd(0.5,0.8) * (0.2+0.8*Math.sin(dr*M.PI)), 0, 0.5);
			p.colorize(c);
			// p.scaleX = R.around(0.1,true);
			// p.moveAng(a, rnd(0,0.1,true));
			p.dx = rnd(0.2,0.4,true);
			// p.gx = rnd(0,0.02,true);
			p.gy = rnd(0,0.02,true);
			p.frict = R.around(0.85);
			// p.rotation = a;
			p.lifeS = rnd(0.5,2);
		}

		// Lines
		var n = 8;
		for(i in 0...n) {
			a = ( 0.1 + 0.8*i/(n-1)) * M.PI;
			var dr = rnd(0,1);
			var p = allocTopAdd( getTile(dict.fxLineThinRight), fx+Math.cos(a)*3, fy+Math.sin(a)*3 );
			p.setFadeS(0.9, 0, 0.5);
			p.colorize(c);
			p.scaleX = R.around(0.2,true);
			p.scaleXMul = 0.97;
			p.frict = R.around(0.85);
			p.moveAng(a, 1.5);
			p.rotation = a;
			p.lifeS = R.around(0.1);
		}
	}


	public function largeExplosion(x:Float,y:Float, radiusPx:Float) {
		var a = 0.;
		var d = 0.;
		var p : HParticle = null;

		p = allocRadius(x,y,40, 0xffcc00, false);
		p.setFadeS(0.7, 0, R.around(0.2));
		p.ds = 0.1;
		p.dsFrict = R.around(0.89);
		p.lifeS = R.around(0.2);

		p = allocRadius(x,y,radiusPx, 0xffcc00, true);
		p.ds = 0.03;
		p.dsFrict = R.around(0.85);
		p.setFadeS(0.7, 0, R.around(0.2));
		p.lifeS = 0.2;

		// Explosion anims
		var n = 60;
		for(i in 0...n) {
			a = R.fullCircle();
			d = rnd(10,radiusPx-20);
			p = allocTopAdd(getTile(dict.fxExplode), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.playAnimAndKill( Assets.tiles, dict.fxExplode, rnd(0.3,0.4) );
			p.setScale(rnd(0.9,2));
			p.moveAwayFrom(x,y, rnd(3,4));
			p.frict = R.aroundZTO(0.86);
			p.rotation = rnd(0, 0.4, true);
			p.delayS = i/(n-1) * 0.1 + R.around(0.1);
		}

		// Long lines
		var n = 30;
		for(i in 0...n) {
			a = M.PI2 * i/(n-1) + R.zeroTo(0.1,true);
			d = R.around(radiusPx*0.6);
			p = allocTopAdd(getTile(dict.fxLineThinLeft), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorizeRandom(0xff0000, 0xffcc00);
			p.setCenterRatio(1,0.5);
			p.scaleY = 2;
			p.scaleX = 0.5*radiusPx / p.t.width;
			// p.dsX = R.around(0.1);
			// p.dsFrict = R.aroundZTO(0.97);
			p.scaleXMul = R.aroundZTO(0.97);
			p.moveAwayFrom(x,y, rnd(2,3));
			p.frict = R.aroundZTO(0.94);
			p.rotation = a;
			p.lifeS = R.around(0.4);
		}

		// Small lines
		var n = 40;
		for(i in 0...n) {
			a = R.fullCircle();
			d = rnd(20,radiusPx*0.5);
			p = allocTopAdd(getTile(dict.fxLineThinLeft), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorizeRandom(0xff0000, 0xffcc00);
			p.scaleX = R.around(2);
			p.scaleXMul = R.aroundZTO(0.96);
			p.moveAwayFrom(x,y, rnd(8,10));
			p.frict = R.aroundZTO(0.94);
			p.rotation = a;
			p.lifeS = R.around(1);
		}

		// Smoke
		var n = 30;
		for(i in 0...n) {
			a = i/(n-1) * M.PI2 + R.zeroTo(0.1,true);
			d = rnd(2,60);
			p = allocTopNormal(getTile(dict.fxSmoke), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.setFadeS( R.around(0.7), 0, R.around(3) );
			p.setScale( R.around(2.5) * R.sign() );
			p.colorAnimS(0x880000, 0x0, R.around(0.7));
			p.moveAwayFrom(x,y, rnd(2,3));
			p.frict = R.aroundZTO(0.9);
			p.rotation = R.fullCircle();
			p.dr = R.around(0.005);
			p.gy = R.around(0.01);
			p.lifeS = rnd(10,12);
		}

		// Dots
		var n = 120;
		for(i in 0...n) {
			a = R.fullCircle();
			d = radiusPx * rnd(0.03,0.45);
			p = allocTopAdd(getTile(dict.pixel), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.alphaFlicker = 0.5;
			p.colorizeRandom(0xff0000, 0xffcc00);
			p.moveAwayFrom(x,y, rnd(3,4));
			p.frict = R.aroundZTO(0.96);
			p.gy = R.zeroTo(0.03);
			p.lifeS = rnd(3,5);
		}
	}

	public inline function explosionWarning(x:Float, y:Float, ratio:Float) {
		var p = allocTopAdd( getTile(dict.lightCircle), x,y );
		p.setFadeS(0.3 + 0.5*ratio, 0, R.around(0.2));
		p.colorize( C.interpolateInt(0xffcc00, 0xff0000, ratio) );
		p.setScale(0.5 + 0.5*ratio);
		p.lifeS = 0.1;
	}

	public inline function fireExtinguishedByExplosion(fireX:Float,fireY:Float, sourceX:Float, sourceY:Float) {
		// Splash
		var n = 9;
		var a = 0.;
		var d = 0.;
		for(i in 0...n) {
			a = (i+1)/n * M.PI2;
			d = rnd(3,6);
			var p = allocBgAdd(getTile(dict.fxFlame), fireX+Math.cos(a)*d, fireY+Math.sin(a)*d);
			p.setFadeS(R.around(0.9), 0, 0.1);
			p.colorize(0x50ccff);
			p.moveAng(a, rnd(3,4));
			p.rotation = a+M.PIHALF;
			p.frict = 0.77;
			p.scaleY = R.around(1.2);
			p.scaleYMul = R.aroundBO(0.96);
			p.lifeS = R.around(0.4);
		}

		// Smoke
		for(i in 0...2) {
			var p = allocTopNormal( getTile(dict.fxSmoke), fireX+R.zeroTo(4,true), fireY+R.zeroTo(4,true) );
			p.setFadeS(R.around(0.5), rnd(0.3,0.5), rnd(0.4,1));
			p.colorAnimS(0xc14132, 0x3b4f77, rnd(0.4, 1.2));
			p.setScale(rnd(1,2,true));
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0,0.03,true);
			p.ds = rnd(0.002, 0.004);
			p.gx = windX*rnd(0.01,0.02);
			p.moveAwayFrom(sourceX,sourceY, R.around(3));
			p.frict = R.aroundZTO(0.92);
			p.lifeS = R.around(1.5);
			p.delayS = rnd(0,0.4);
		}
	}


	public function announceRadius(x:Float, y:Float, r:Float, c:UInt) {
		// Filled halo
		var p = allocRadius(x,y,r,c, true);
		p.setFadeS(0.5, 0.1, 0.1);
		p.ds = 0.02;
		p.dsFrict = 0.8;
		p.lifeS = 0.1;

		// Outer line
		var p = allocRadius(x,y,r,c, false);
		p.setFadeS(0.8, 0, 0.1);
		p.ds = 0.02;
		p.dsFrict = 0.8;
		p.lifeS = 0.03;

		// Inner line
		var p = allocRadius(x,y,r*0.25,c, false);
		p.setFadeS(0.8, 0, 0.1);
		p.ds = 0.05;
		p.dsFrict = 0.8;
		p.lifeS = 0.03;
	}


	public function allocRadius(x:Float, y:Float, r:Float, c:UInt, fill:Bool) {
		var p = allocBgNormal( getTile(dict.empty), x,y);
		p.lifeS = R.around(1);
		var g = new h2d.Graphics(graphics);
		if( fill )
			g.beginFill(c, 0.5);
		else
			g.lineStyle(1, c, 1);
		g.drawCircle(0,0,r);
		g.alpha = 0; // to avoid 1st frame flickering
		p.onUpdate = (_)->{
			g.setPosition(p.x, p.y);
			g.alpha = p.alpha;
			g.scaleX = p.scaleX;
			g.scaleY = p.scaleY;
		}
		p.onKill = g.remove;
		return p;
	}



	function _woodPhysics(p:HParticle) {
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
			p.setScale(R.aroundZTO(1));
			p.dx = dir*rnd(3,12);
			p.dy = rnd(-0.6,0.1);
			p.frict = R.aroundZTO(0.96);
			p.gy = rnd(0.05,0.1);
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0.1,0.4,true);
			p.setFadeS(R.aroundZTO(0.9), 0, R.around(2));
			p.onUpdate = _woodPhysics;
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
			p.setFadeS(rnd(0.8,1), 0, R.around(0.2));
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
			p.colorAnimS( 0xffcc00, 0x9e62f1, R.around(0.3) );
			p.scaleX = R.around(0.1);
			p.setFadeS(R.around(0.9), 0.03, R.around(0.1));
			p.frict = R.aroundZTO(0.9);
			p.moveAng(ang, R.around(2));
			p.rotation = p.getMoveAng();
			p.lifeS = R.around(0.1);
			p.delayS = R.around(0.1);
		}

		// Sparks
		for(i in 0...3) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,1,true), y+rnd(0,1,true) );
			p.colorAnimS( 0xffcc00, 0xff0000, R.around(0.3) );
			p.setFadeS(R.around(0.9), 0.03, R.around(0.1));
			p.alphaFlicker = 0.6;
			p.scaleX = 2;

			p.frict = R.aroundZTO(0.9);
			p.moveAng(ang+rnd(0,1,true), rnd(0.5,2));
			p.gy = R.around(0.03);
			p.autoRotateSpeed = 1;

			p.lifeS = R.around(0.6);
			p.delayS = R.around(0.1);
		}

		// Flames
		var n = dist<=Const.GRID*1.5 ? 2 : 3;
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxFlame), x+rnd(0,2,true), y+rnd(0,2,true) );
			p.setFadeS(R.around(0.8), R.around(0.03), R.around(0.2));
			p.colorAnimS( C.interpolateInt(0xffdd88, 0xff4400, rnd(0,1)), 0x9e62f1, R.around(0.3) );
			p.rotation = -rnd(0.1,0.2);

			p.scaleX = R.around(0.3) * rndSign();
			p.scaleY = R.around(1);
			p.scaleYMul = rnd(0.96,0.98);
			// p.scaleYMul = rnd(1,1.03);

			p.moveAng(ang+R.zeroTo(0.05,true), 2.3*(dist/Const.GRID)+rnd(0,0.2,true));
			p.rotation = ang + M.PIHALF;
			p.frict = 0.85 + rnd(0,0.02);

			p.lifeS = R.around(0.2);
			p.delayS = i==0 ? 0 : R.around(0.06);
		}
	}



	public function flyFireSpray(x:Float,y:Float, ang:Float, dist:Float) {
		// Core dots
		for(i in 0...2) {
			var p = allocTopAdd( getTile(dict.fxLine), x,y);
			p.colorAnimS( 0xffcc00, 0x9e62f1, R.around(0.3) );
			p.scaleX = R.around(0.1);
			p.setFadeS(R.around(0.9), 0.03, R.around(0.1));
			p.frict = R.aroundZTO(0.9);
			p.moveAng(ang, R.around(2));
			p.rotation = p.getMoveAng();
			p.lifeS = R.around(0.1);
			p.delayS = R.around(0.1);
		}


		// Flames
		var n = dist<=Const.GRID*1.5 ? 2 : 3;
		for(i in 0...n) {
			var p = allocTopAdd( getTile(dict.fxFlame), x+rnd(0,2,true), y+rnd(0,2,true) );
			p.setFadeS(R.around(0.8), R.around(0.03), R.around(0.2));
			p.colorAnimS( C.interpolateInt(0xff8800, 0xff0000, rnd(0,1)), 0x1b1b5f, R.around(0.4) );
			p.rotation = -rnd(0.1,0.2);

			p.scaleX = R.around(0.3) * rndSign();
			p.scaleY = R.around(1);
			p.scaleYMul = rnd(0.96,0.98);
			p.dsX = R.around(0.2);
			p.dsFrict = 0.91;

			p.moveAng(ang+R.zeroTo(0.05,true), 2.3*(dist/Const.GRID)+rnd(0,0.2,true));
			p.rotation = ang + M.PIHALF;
			p.frict = 0.85 + rnd(0,0.02);

			p.lifeS = R.around(0.2);
			p.delayS = i==0 ? 0 : R.around(0.06);
		}
	}


	public function fastFalling(x:Float, y:Float, ratio:Float) {
		for(i in 0...irnd(1,2)) {
			var p = allocBgAdd( getTile(dict.fxLine), x+rnd(0,6,true), y );
			p.setFadeS( R.around(0.1)*ratio, R.around(0.2), R.around(0.2) );
			p.dy = -rnd(1,2)*ratio;
			p.rotation = -M.PIHALF;
			p.lifeS = R.around(0.2);
		}
	}


	public function heavyLand(x:Float, y:Float, pow:Float, smoke=true) {
		var col = C.hexToInt("#ab7f7a");

		// Small hit lines
		final n = Std.int(pow*30);
		var range = M.PI*0.6;
		for(i in 0...n) {
			var pow = 0.55 + 0.45*Math.sin( M.PI * i/(n-1) );
			var a = -M.PIHALF - range*0.5 + range*i/(n-1) + rnd(0,0.15,true);
			var p = allocBgAdd( getTile(dict.fxLineThinRight), x+Math.cos(a)*4, y+Math.sin(a)*4 );
			p.colorize(col);
			p.setCenterRatio(0, 0.5);
			p.scaleX = rnd(0.3,0.6) * pow;
			p.dsX = rnd(0.45,0.50) * pow;
			p.dsFrict = 0.92;
			p.scaleXMul = R.around(0.8,5);
			p.rotation = a;
			p.lifeS = R.around(0.2);
		}

		// Core hit lines
		if( pow>=1 ) {
			final n = Std.int(pow*10);
			for(i in 0...n) {
				var p = allocBgAdd( getTile(dict.fxLineThinRight), x+rnd(0,6,true), y );
				p.colorize(col);
				p.setCenterRatio(0, 0.5);
				p.scaleX = rnd(2,3);
				p.dsX = rnd(0.35,0.40);
				p.dsFrict = 0.92;
				p.scaleXMul = R.around(0.9,5);
				p.rotation = -M.PIHALF;
				p.lifeS = R.around(0.2);
			}
		}

		// Core dirt
		final n = Std.int(pow*50);
		for(i in 0...n) {
			var p = allocTopNormal( getTile(dict.fxDirt), x+rnd(0,6,true), y );
			p.setFadeS( rnd(0.2,1), 0, R.around(1));
			p.colorize(col);
			p.randScale(0.3,0.8,true);
			p.dx = rnd(0,1,true);
			p.dy = -rnd(2, 8);
			p.gy = R.around(0.09);
			p.frict = R.around(0.92,3);
			p.dr = rnd(0.1,0.4,true);
			p.drFrict = R.around(0.95);
			p.rotation = R.fullCircle();
			p.lifeS = rnd(1,3);
			p.onUpdate = _dirtPhysics;
		}
		// Falling dust
		final n = Std.int(pow*30);
		for(i in 0...n) {
			var p = allocTopNormal( getTile(dict.pixel), x+rnd(0,10,true), y-rnd(30,80) );
			p.setFadeS( R.around(0.4), R.around(0.2), R.around(1));
			p.colorize(col);
			p.gy = rnd(0.01,0.04);
			p.frict = R.around(0.92,10);
			p.lifeS = rnd(1,3);
			p.onUpdate = _dustPhysics;
			p.delayS = rnd(0,1);
		}
		// Ground smoke
		if( smoke ) {
			final n = Std.int(pow*40);
			for(i in 0...n) {
				var p = allocTopNormal( getTile(dict.fxSmoke), x+rnd(0,10,true), y-rnd(0,10) );
				p.setFadeS( R.around(0.2), 0, R.around(3,30));
				p.colorize( C.toBlack(col, rnd(0,0.5)) );
				p.frict = R.around(0.88,4);
				p.dx = rnd(0,2,true);
				p.dy = -rnd(0,1);
				p.gx = M.sign(p.dx) * rnd(0,0.03);
				p.gy = -rnd(0,0.02);
				p.rotation = R.fullCircle();
				p.dr = R.around(0.008, true);
				p.lifeS = rnd(1,3);
			}
		}
	}


	function _drip(p:HParticle) {
		p.data0 -= tmod/Const.FPS;

		// Start falling
		if( p.data0<=0 && p.data1!=1 ) {
			p.data1 = 1;
			p.gy = R.around(0.15);
			p.frict = R.around(0.92, 5);
		}

		// Only start colliding after passing over empty spaces
		if( !collides(p) )
			p.data2 = 1;

		// Small drips when hitting ground
		if( p.data1==1 && p.data2==1 && collides(p) ) {
			for(i in 0...irnd(2,4)) {
				var d = allocBgAdd( getTile(dict.pixel), p.x+rnd(0,2,true), p.y-rnd(0,2) );
				d.setFadeS(rnd(0.1,0.4), 0, 0.1);
				d.moveAwayFrom(p.x,p.y, rnd(0.3,0.8));
				d.gy = R.around(0.03);
				d.frict = R.around(0.93);
				d.onUpdate = _waterPhysics;
				d.lifeS = R.around(0.2);
			}
			p.kill();
		}
	}

	public function drips(x:Float, y:Float, c:Int) {
		var p = allocTopAdd( getTile(dict.fxLineThinLeft), x, y-irnd(0,2) );
		p.colorize(c);
		p.setFadeS( rnd(0.1,0.4), R.around(0.3), R.around(0.2));
		p.setCenterRatio(1,0.5);
		p.dy = R.around(0.05);
		p.frict = 0.94;

		p.scaleX = R.around(0.1,5);
		p.data0 = rnd(0.5,1.5);
		p.rotation = M.PIHALF;

		p.onUpdate = _drip;
		p.lifeS = R.around(3);
		p.delayS = rnd(0,0.3);
	}

	public function computerLights(x:Float, y:Float, w:Float, h:Float, c:Int) {
		final step = 2;
		final p = 3;
		for(i in 0...irnd(8,12)) {
			var p = allocTopAdd( getTile(Std.random(100)<80 ? dict.pixel : dict.fxDot), rnd(x+p,x+w-p), rnd(y+p,y+h-p) );
			p.setFadeS( rnd(0.4,1), 0, rnd(0.06,0.3));
			p.x = Std.int(p.x/step)*step;
			p.y = Std.int(p.y/step)*step;
			p.colorize(c);
			p.lifeS = rnd(0.1,0.5);
			p.delayS = rnd(0,0.2);
		}
	}

	public function usedItem(x:Float, y:Float, c:Int) {
		var p = allocRadius(x,y, 16, c, false);
		p.setScale(0.3);
		p.setFadeS(0.7, 0, 0.3);
		p.ds = 0.1;
		p.dsFrict = 0.93;
		p.lifeS = 0.06;

		// Dots
		var n = 20;
		for(i in 0...n) {
			var a = M.PI2 * i/n + rnd(0,0.2,true);
			var p = allocTopAdd(getTile(dict.pixel), x+Math.cos(a)*3, y+Math.sin(a)*3);
			p.setFadeS(R.aroundBO(0.9), 0, rnd(1,2));
			p.colorize(c);
			p.moveAwayFrom(x,y, rnd(2,3));
			p.frict = R.around(0.93, 4);
			p.lifeS = R.around(0.5);
		}
	}

	public function groundSparks(x:Float, y:Float, w:Float, c:Int) {
		for(i in 0...irnd(2,4)) {
			var p = allocTopAdd( getTile(dict.pixel), rnd(x,x+w), y );
			p.setFadeS( rnd(0.4,1), 0, rnd(0.06,0.3));
			p.alphaFlicker = 0.5;
			p.colorAnimS(c, 0x3957b5, rnd(0.2,0.5));
			p.dx = rnd(0,0.2,true);
			p.dy = -rnd(0.2,0.8);
			p.gy = R.around(0.06);
			p.lifeS = rnd(0.1,0.5);
			p.delayS = rnd(0,0.2);
			p.onUpdate = _dustPhysics;
		}
	}

	public function mediumLand(x:Float, y:Float, pow:Float) {
		var col = C.hexToInt("#ab7f7a");

		// Small hit lines
		final n = Std.int(pow*10);
		var range = M.PI*0.6;
		for(i in 0...n) {
			var pow = 0.55 + 0.45*Math.sin( M.PI * i/(n-1) );
			var a = -M.PIHALF - range*0.5 + range*i/(n-1) + rnd(0,0.15,true);
			var p = allocBgAdd( getTile(dict.fxLineThinRight), x+Math.cos(a)*4, y+Math.sin(a)*4 );
			p.alpha = R.around(0.2)*pow;
			p.colorize(col);
			p.setCenterRatio(0, 0.5);
			p.scaleX = rnd(0.1,0.2) * pow;
			p.dsX = rnd(0.45,0.50) * pow;
			p.dsFrict = 0.92;
			p.scaleXMul = R.around(0.8,5);
			p.rotation = a;
			p.lifeS = R.around(0.2);
		}

		// Core dirt
		final n = Std.int(pow*20);
		for(i in 0...n) {
			var p = allocTopNormal( getTile(dict.fxDirt), x+rnd(0,6,true), y );
			p.setFadeS( rnd(0.2,1), 0, R.around(1));
			p.colorize(col);
			p.randScale(0.3,0.8,true);
			p.dx = rnd(0.5,2,true);
			p.dy = -rnd(1, 2);
			p.gy = R.around(0.12);
			p.frict = R.around(0.92,3);
			p.dr = rnd(0.1,0.4,true);
			p.drFrict = R.around(0.95);
			p.rotation = R.fullCircle();
			p.lifeS = rnd(1,3);
			p.onUpdate = _dirtPhysics;
		}
		// Falling dust
		final n = Std.int(pow*30);
		for(i in 0...n) {
			var p = allocTopNormal( getTile(dict.pixel), x+rnd(0,10,true), y-rnd(10,30) );
			p.setFadeS( R.around(0.4), R.around(0.2), R.around(1));
			p.colorize(col);
			p.gy = rnd(0.01,0.04);
			p.frict = R.around(0.92,10);
			p.lifeS = rnd(1,3);
			p.onUpdate = _dustPhysics;
			p.delayS = rnd(0,1);
		}
		// Ground smoke
		final n = Std.int(pow*10);
		for(i in 0...n) {
			var p = allocTopNormal( getTile(dict.fxSmoke), x+rnd(0,10,true), y-rnd(0,3) );
			p.setFadeS( R.around(0.2), 0, R.around(1,30));
			p.colorize( C.toBlack(col, rnd(0,0.5)) );
			p.randScale(0.3,0.4,true);
			p.frict = R.around(0.88,4);
			p.dx = rnd(0,2,true);
			p.dy = -rnd(0,1);
			p.gx = M.sign(p.dx) * rnd(0,0.03);
			p.gy = -rnd(0,0.02);
			p.rotation = R.fullCircle();
			p.dr = R.around(0.008, true);
			p.lifeS = rnd(0.8,1);
		}
	}


	public function lightLand(x:Float, y:Float) {
		for(i in 0...8) {
			var p = allocBgNormal( getTile(dict.pixel), x, y );
			p.setFadeS(rnd(0.4,0.7), 0.06, R.around(0.2));
			p.colorize(0xcbb5a0);
			p.dx = rnd(0.5,2,true);
			p.dy = -rnd(0.5,1.5);
			p.gy = rnd(0.05,0.10);
			p.frict = rnd(0.8,0.92);
			p.lifeS = rnd(0.1,0.5);
			p.onUpdate = _dustPhysics;
		}
	}


	public function fireSprayOffSmoke(x:Float,y:Float, ang:Float, dist:Float) {
		// Smoke
		for(i in 0...2) {
			var p = allocBgNormal( getTile(dict.fxSmoke), x+rnd(0,1,true), y+rnd(0,1,true) );
			p.colorAnimS( 0xff8210, 0xb1b8d5, R.around(0.3) );
			p.setFadeS(R.around(0.2), 0.03, R.around(0.3));
			p.setScale( R.around(0.04) );
			p.ds = R.around(0.015, 5);
			p.dsFrict = R.around(0.91,3);
			p.rotation = R.fullCircle();
			p.dr = R.around(0.003);

			p.moveAng(ang, R.around(0.7,3));
			p.frict = R.aroundZTO(0.95,1);
			// p.gy = -R.around(0.01);
			p.autoRotateSpeed = 1;

			p.lifeS = R.around(0.6);
			p.delayS = R.zeroTo(0.3);
		}
	}

	function _waterRefillerPhysics(p:HParticle) {
		if( p.y<=p.data0 ) {
			p.gy = p.dy = 0;
			p.scaleY = 1;
		}
	}

	public function waterRefiller(x:Float, y:Float) {
		var p = allocBgAdd(getTile(dict.pixel), x+rnd(0,2,true), y-rnd(0,4));
		p.colorize(0x7cfffa);
		p.setFadeS(rnd(0.2,1), R.around(0.1), R.around(0.5));
		p.gy = -rnd(0.01,0.05);
		p.frict = R.around(0.87);
		p.data0 = y-18;
		p.onUpdate = _waterRefillerPhysics;
		p.lifeS = R.around(0.3);
	}

	public function waterRefillerUsed(x:Float, y:Float, tx:Float, ty:Float) {
		// Bubbles
		var p = allocBgAdd(getTile(dict.pixel), x+rnd(0,2,true), y-rnd(1,4));
		p.colorize(0x7cfffa);
		p.scaleY = rnd(2,3);
		p.setFadeS(rnd(0.6,1), 0, R.around(0.2));
		p.gy = -rnd(0.05,0.07);
		p.frict = R.around(0.92);
		p.data0 = y-16;
		p.onUpdate = _waterRefillerPhysics;
		p.lifeS = R.around(0.2);

		// Link
		var p = allocTopAdd(getTile(dict.fxLightning), x+rnd(0,2,true), y-rnd(1,4));
		p.setCenterRatio(0,0.5);
		p.colorize(0x7cfffa);
		p.rotation = M.angTo(x,y,tx,ty);
		p.scaleX = M.dist(x,y,tx,ty)/p.t.width;
		p.setFadeS(rnd(0.7,0.8), 0.03, R.around(0.1));
		p.lifeS = R.around(0.06);
	}

	public function waterRefillerPhong(x:Float, y:Float) {
		var p = allocBgAdd(getTile(dict.fxWaterPhong), x, y);
		p.alpha = 0.85;
		p.playAnimAndKill(Assets.tiles, dict.fxWaterPhong, 0.5);
	}


	public function mobHit(x:Float, y:Float, dir:Int) {
		var n = 20;
		for(i in 0...n) {
			var d = rnd(3,6);
			var p = allocTopAdd(getTile(dict.fxLineThinLeft), x+rnd(0,5,true), y+rnd(0,7,true));
			p.colorize(0x50ccff);
			p.scaleX = R.around(0.2);
			p.moveAwayFrom(x,y, rnd(2,3));
			p.rotation = p.getMoveAng();
			p.autoRotateSpeed = 0.9;
			p.gy = R.around(0.07);
			p.frict = R.aroundBO(0.9);
			p.scaleXMul = R.aroundBO(0.92);
			p.lifeS = R.around(0.3);
			// p.onUpdate = _waterPhysics;
		}
	}

	public function waterRefillerComplete(x:Float, y:Float) {
		// Lines
		var n = 40;
		for(i in 0...n) {
			var a = (i+1)/n * M.PI2;
			var d = rnd(3,6);
			var p = allocTopAdd(getTile(dict.fxLineThinLeft), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorize(0x50ccff);
			p.scaleX = R.around(0.2);
			p.moveAng(a, rnd(3,4));
			p.rotation = a;
			p.autoRotateSpeed = 0.9;
			p.gy = R.around(0.07);
			p.frict = R.aroundBO(0.82);
			p.scaleXMul = R.aroundBO(0.92);
			p.lifeS = R.around(0.3);
		}

		// Inner
		var n = 11;
		for(i in 0...n) {
			var a = (i+1)/n * M.PI2;
			var d = rnd(3,6);
			var p = allocTopAdd(getTile(dict.fxWaterSurface), x+Math.cos(a)*d, y+Math.sin(a)*d);
			p.colorize(0x50ccff);
			p.moveAng(a, rnd(3,4));
			p.rotation = a+M.PIHALF;
			p.frict = 0.68;
			p.scaleY = R.around(1.2);
			p.scaleYMul = R.aroundBO(0.96);
			p.lifeS = R.around(0.2);
		}
	}

	public function fireSprayOffSparks(x:Float,y:Float, ang:Float, dist:Float) {
		// Core
		for(i in 0...3) {
			var p = allocTopAdd( getTile(dict.fxDot), x+rnd(0,1,true), y+rnd(0,1,true) );
			p.colorAnimS( 0xff4400, 0x990000, R.around(0.3) );
			p.setFadeS(R.around(0.9), 0.03, R.around(0.1));
			p.rotation = R.fullCircle();
			p.alphaFlicker = 0.6;
			p.frict = R.aroundZTO(0.84);
			p.gy = R.zeroTo(0.01);
			p.autoRotateSpeed = 1;
			p.lifeS = R.around(0.9);
			p.delayS = R.zeroTo(0.2);
		}

		// Sparks
		for(i in 0...irnd(1,2)) {
			var p = allocTopAdd( getTile(dict.pixel), x+rnd(0,1,true), y+rnd(0,1,true) );
			p.colorAnimS( 0xff8800, 0x880000, R.around(0.3) );
			p.setFadeS(R.around(0.9), 0.03, R.around(0.1));
			p.alphaFlicker = 0.6;
			p.scaleX = 2;

			p.frict = R.aroundZTO(0.84);
			p.moveAng(ang+rnd(0,1,true), rnd(0.5,2));
			p.gy = R.around(0.02);
			p.autoRotateSpeed = 1;

			p.lifeS = R.around(0.6);
			p.delayS = R.zeroTo(0.2);
		}
	}


	override function update() {
		super.update();

		windX = Math.cos(ftime*0.01);
		pool.update(game.tmod);
	}
}