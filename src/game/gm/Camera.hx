package gm;

typedef CinematicTarget = {
	var x : Float;
	var y : Float;
	var durationS : Float;
}

class Camera extends dn.Process {
	/** Camera focus coord in level pixels. This is the raw camera location: the actual camera location might be clamped to level bounds. **/
	public var rawFocus : LPoint;

	/** This is equal to rawFocus if `clampToLevelBounds` is disabled **/
	var clampedFocus : LPoint;

	var target : Null<Entity>;
	public var trackingOffX = 0.;
	public var trackingOffY = 0.;
	var extraOffX = 0.;
	var extraOffY = 0.;

	/** Width of viewport in level pixels **/
	public var pxWid(get,never) : Int;

	/** Height of viewport in level pixels **/
	public var pxHei(get,never) : Int;

	/** Horizontal camera dead-zone in percentage of viewport width **/
	public var deadZonePctX = 0.04;

	/** Verticakl camera dead-zone in percentage of viewport height **/
	public var deadZonePctY = 0.08;

	var baseFrict = 0.86;
	var dx : Float;
	var dy : Float;
	var bumpOffX = 0.;
	var bumpOffY = 0.;
	var bumpFrict = 0.96;
	var bumpZoomFactor = 0.;

	/** Zoom factor **/
	public var targetZoom(default,set) = 1.0;
	var curZoom = 1.;
	public var zoom(get,never) : Float;

	/** Speed multiplier when camera is tracking a target **/
	var baseTrackingSpeed = 1.0;

	/** If TRUE (default), the camera will try to stay inside level bounds. It cannot be done if level is smaller than actual viewport. In such case, the camera will be centered. **/
	public var clampToLevelBounds = false;
	var brakeDistNearBounds = 0.1;

	/** Left camera bound in level pixels **/
	public var left(get,never) : Int;
		inline function get_left() return Std.int( clampedFocus.levelX - pxWid*0.5 );

	/** Right camera bound in level pixels **/
	public var right(get,never) : Int;
		inline function get_right() return Std.int( left + (pxWid - 1) );

	/** Upper camera bound in level pixels **/
	public var top(get,never) : Int;
		inline function get_top() return Std.int( clampedFocus.levelY-pxHei*0.5 );

	/** Lower camera bound in level pixels **/
	public var bottom(get,never) : Int;
		inline function get_bottom() return top + pxHei - 1;

	public var centerX(get,never) : Int;
		inline function get_centerX() return Std.int( (left+right) * 0.5 );

	public var centerY(get,never) : Int;
		inline function get_centerY() return Std.int( (top+bottom) * 0.5 );

	// Debugging
	var invalidateDebugBounds = false;
	var debugBounds : Null<h2d.Graphics>;

	var cinematicPoints : Array<CinematicTarget> = [];


	public function new() {
		super(Game.ME);
		rawFocus = LPoint.fromCase(0,0);
		clampedFocus = LPoint.fromCase(0,0);
		clampToLevelBounds = true;
		dx = dy = 0;
	}

	@:keep
	override function toString() {
		return 'Camera@${rawFocus.levelX},${rawFocus.levelY}';
	}

	inline function set_targetZoom(v) {
		return targetZoom = M.fclamp(v, 1, Const.db.MaxCameraZoom);
	}

	public inline function bumpZoom(z:Float) {
		bumpZoomFactor = M.fmax(bumpZoomFactor, z);
	}

	inline function get_zoom() {
		return M.fclamp( curZoom + bumpZoomFactor, 1, Const.db.MaxCameraZoom );
	}

	function get_pxWid() {
		return M.ceil( Game.ME.w() / Const.SCALE / zoom );
	}

	function get_pxHei() {
		return M.ceil( Game.ME.h() / Const.SCALE / zoom );
	}

	public inline function isOnScreen(levelX:Float, levelY: Float, padding=0.) {
		return levelX>=left-padding && levelX<=right+padding && levelY>=top-padding && levelY<=bottom+padding;
	}

	public inline function isOnScreenRect(x:Float, y:Float, wid:Float, hei:Float, padding=0.) {
		return Lib.rectangleOverlaps(
			left-padding, top-padding, pxWid+padding*2, pxHei+padding*2,
			x, y, wid, hei
		);
	}

	public inline function isOnScreenCase(cx:Int, cy:Int, padding=32) {
		return cx*Const.GRID>=left-padding && (cx+1)*Const.GRID<=right+padding
			&& cy*Const.GRID>=top-padding && (cy+1)*Const.GRID<=bottom+padding;
	}

	public function trackEntity(e:Entity, immediate:Bool, speed=1.0) {
		target = e;
		setTrackingSpeed(speed);
		if( immediate || rawFocus.levelX==0 && rawFocus.levelY==0 )
			centerOnTarget();
	}

	public function cinematicTrack(x:Float, y:Float, durationS:Float) {
		cinematicPoints.push({
			x: x,
			y: y,
			durationS: durationS,
		});
	}

	public function reset() {
		clearCinematicTrackings();
		setShoulderIntensity(0);
		cd.unset("shaking");
	}

	public function clearCinematicTrackings() {
		cinematicPoints = [];
	}

	public inline function setTrackingSpeed(spd:Float) {
		baseTrackingSpeed = M.fclamp(spd, 0.01, 10);
	}

	inline function getTrackingSpeedMul() {
		return !hasCinematicTracking() ? baseTrackingSpeed : 1.25;
	}

	public inline function stopTracking() {
		target = null;
	}

	public function centerOnTarget() {
		if( target!=null ) {
			rawFocus.levelX = target.centerX + trackingOffX;
			rawFocus.levelY = target.centerY + trackingOffY;
		}
	}

	public inline function levelToGlobalX(v:Float) return v*Const.SCALE + Game.ME.scroller.x;
	public inline function levelToGlobalY(v:Float) return v*Const.SCALE + Game.ME.scroller.y;

	var shakePower = 0.;
	public function shakeS(t:Float, ?pow=1.0) {
		cd.setS("shaking", t, true);
		shakePower = pow;
	}

	var shoulderPower = 0.;
	public function setShoulderIntensity(pow:Float) {
		shoulderPower = pow;
	}

	public inline function bumpAng(a, dist) {
		bumpOffX+=Math.cos(a)*dist;
		bumpOffY+=Math.sin(a)*dist;
	}

	public inline function bump(x,y) {
		bumpOffX+=x;
		bumpOffY+=y;
	}


	/** Apply camera values to Game scroller **/
	function apply() {
		if( ui.Console.ME.hasFlag("scroll") )
			return;

		var level = Game.ME.level;
		var scroller = Game.ME.scroller;

		// Update scroller
		scroller.x = -clampedFocus.levelX + pxWid*0.5;
		scroller.y = -clampedFocus.levelY + pxHei*0.5;

		// Bumps friction
		bumpOffX *= Math.pow(bumpFrict, tmod);
		bumpOffY *= Math.pow(bumpFrict, tmod);

		// Bump
		scroller.x -= bumpOffX;
		scroller.y -= bumpOffY;

		// Shakes
		if( cd.has("shaking") ) {
			scroller.x += Math.cos(ftime*1.1)*2.5*shakePower * cd.getRatio("shaking");
			scroller.y += Math.sin(0.3+ftime*1.7)*2.5*shakePower * cd.getRatio("shaking");
		}

		// Shoulder effect
		if( shoulderPower>0 ) {
			scroller.x += Math.cos(ftime*0.026) * 7 * shoulderPower;
			scroller.y += Math.sin(ftime*0.011 + 1) * 5 * shoulderPower;
		}

		// Scaling
		scroller.x*=Const.SCALE*zoom;
		scroller.y*=Const.SCALE*zoom;

		// Rounding
		scroller.x = M.round(scroller.x);
		scroller.y = M.round(scroller.y);

		// Zoom
		scroller.setScale(Const.SCALE * zoom);
	}


	public function disableDebugBounds() {
		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}
	}
	public function enableDebugBounds() {
		disableDebugBounds();
		debugBounds = new h2d.Graphics();
		Game.ME.scroller.add(debugBounds, Const.DP_TOP);
		invalidateDebugBounds = true;
	}

	function renderDebugBounds() {
		debugBounds.clear();

		debugBounds.lineStyle(2,0xff00ff);
		debugBounds.drawRect(0,0,pxWid,pxHei);

		debugBounds.moveTo(pxWid*0.5, 0);
		debugBounds.lineTo(pxWid*0.5, pxHei);

		debugBounds.moveTo(0, pxHei*0.5);
		debugBounds.lineTo(pxWid, pxHei*0.5);
	}


	override function onResize() {
		super.onResize();
		invalidateDebugBounds = true;
	}


	override function postUpdate() {
		super.postUpdate();

		apply();

		// Debug bounds
		if( ui.Console.ME.hasFlag("cam") && debugBounds==null )
			enableDebugBounds();
		else if( !ui.Console.ME.hasFlag("cam") && debugBounds!=null )
			disableDebugBounds();

		if( debugBounds!=null ) {
			if( invalidateDebugBounds ) {
				renderDebugBounds();
				invalidateDebugBounds = false;
			}
			debugBounds.setPosition(left,top);
		}
	}


	public inline function hasCinematicTracking() {
		return cinematicPoints.length>0;
	}


	override function update() {
		super.update();

		final level = Game.ME.level;

		// Zoom interpolation
		curZoom += ( targetZoom - curZoom ) * M.fmin(1, tmod*0.2);
		bumpZoomFactor *= Math.pow(0.9, tmod);

		// Get tracking coord
		var tx = -1.;
		var ty = -1.;
		if( cinematicPoints.length>0 ) {
			var c = cinematicPoints[0];
			c.durationS -= tmod * 1/Const.FPS;
			if( c.durationS<=0 )
				cinematicPoints.shift();
			else
				tx = c.x;
				ty = c.y;
		}
		if( cinematicPoints.length==0 && target!=null ) {
			tx = target.centerX;
			ty = target.centerY;
		}

		// LDtk camera offsets
		for(e in gm.en.CameraOffset.ALL)
			if( e.isActive() ) {
				tx+=e.data.f_offsetX;
				ty+=e.data.f_offsetY;
			}

		// Follow target
		if( tx>=0 ) {
			var spdX = 0.015*getTrackingSpeedMul()*zoom;
			var spdY = 0.023*getTrackingSpeedMul()*zoom;
			var tx = tx + trackingOffX;
			var ty = ty + trackingOffY;

			var dzMul = cd.has("hasOffset") ? 0.45 : 1;

			var a = rawFocus.angTo(tx,ty);
			var distX = M.fabs( tx - rawFocus.levelX );
			if( distX>=deadZonePctX*pxWid*dzMul )
				dx += Math.cos(a) * (0.8*distX-deadZonePctX*pxWid*dzMul) * spdX * tmod;

			var distY = M.fabs( ty - rawFocus.levelY );
			if( distY>=deadZonePctY*pxHei*dzMul )
				dy += Math.sin(a) * (0.8*distY-deadZonePctY*pxHei*dzMul) * spdY * tmod;
		}

		if( Console.ME.hasFlag("cam") )
			Game.ME.fx.markerFree(tx,ty, 0.03);

		// Compute frictions
		var frictX = baseFrict - getTrackingSpeedMul()*zoom*0.027*baseFrict;
		var frictY = frictX;
		if( clampToLevelBounds ) {
			// "Brake" when approaching bounds
			final brakeDist = brakeDistNearBounds * pxWid;
			if( dx<=0 ) {
				final brakeRatio = 1-M.fclamp( ( rawFocus.levelX - pxWid*0.5 ) / brakeDist, 0, 1 );
				frictX *= 1 - 1*brakeRatio;
			}
			else if( dx>0 ) {
				final brakeRatio = 1-M.fclamp( ( (level.pxWid-pxWid*0.5) - rawFocus.levelX ) / brakeDist, 0, 1 );
				frictX *= 1 - 0.9*brakeRatio;
			}

			final brakeDist = brakeDistNearBounds * pxHei;
			if( dy<0 ) {
				final brakeRatio = 1-M.fclamp( ( rawFocus.levelY - pxHei*0.5 ) / brakeDist, 0, 1 );
				frictY *= 1 - 0.9*brakeRatio;
			}
			else if( dy>0 ) {
				final brakeRatio = 1-M.fclamp( ( (level.pxHei-pxHei*0.5) - rawFocus.levelY ) / brakeDist, 0, 1 );
				frictY *= 1 - 0.9*brakeRatio;
			}
		}

		// Apply velocities
		rawFocus.levelX += dx*tmod;
		dx *= Math.pow(frictX,tmod);
		rawFocus.levelY += dy*tmod;
		dy *= Math.pow(frictY,tmod);

		var rawOffsetedX = rawFocus.levelX + extraOffX;
		var rawOffsetedY = rawFocus.levelY + extraOffY;


		// Bounds clamping
		if( clampToLevelBounds ) {
			// X
			if( level.pxWid < pxWid)
				clampedFocus.levelX = level.pxWid*0.5; // centered small level
			else
				clampedFocus.levelX = M.fclamp( rawOffsetedX, pxWid*0.5, level.pxWid-pxWid*0.5 );

			// Y
			if( level.pxHei < pxHei)
				clampedFocus.levelY = level.pxHei*0.5; // centered small level
			else
				clampedFocus.levelY = M.fclamp( rawOffsetedY, pxHei*0.5, level.pxHei-pxHei*0.5 );
		}
		else {
			// No clamping
			clampedFocus.levelX = rawOffsetedX;
			clampedFocus.levelY = rawOffsetedY;
		}


		for(e in gm.en.Tutorial.ALL)
			e.updatePos();
	}

}