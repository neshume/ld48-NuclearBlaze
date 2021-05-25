package gm.en.int;

class HorizontalDoor extends Entity {
	public static var ALL : Array<HorizontalDoor> = [];
	public var closed(default,null) = true;
	var cWid = 0;
	public var data : Entity_HorizontalDoor;
	var leftDoor : h2d.ScaleGrid;
	var rightDoor : h2d.ScaleGrid;
	var closedFactor = 1.0;

	public function new(d:Entity_HorizontalDoor) {
		super(d.cx,d.cy);
		data = d;
		ALL.push(this);

		setPosPixel(data.pixelX, data.pixelY);
		collides = false;
		gravityMul = 0;
		triggerId = data.f_triggerId;
		Game.ME.scroller.add(spr, Const.DP_BG);
		pivotX = data.pivotX;
		pivotY = data.pivotY;

		var tid = data.f_thin ? dict.doorHorizontalThinLeft : dict.doorHorizontalLeft;
		leftDoor = new h2d.ScaleGrid(Assets.tiles.getTile(tid), 5,8,3,8, spr);
		leftDoor.tileBorders = true;
		leftDoor.height = leftDoor.tile.height;

		var tid = data.f_thin ? dict.doorHorizontalThinRight : dict.doorHorizontalRight;
		rightDoor = new h2d.ScaleGrid(Assets.tiles.getTile(tid), 3,8,5,8, spr);
		rightDoor.tileBorders = true;
		rightDoor.height = rightDoor.tile.height;

		cWid = M.round(d.width / Const.GRID);
		wid = cWid*Const.GRID;
		closed = !d.f_startOpen;
		updateCollisions();

		for(x in cx...cx+cWid)
			level.setMark(HDoorZone, x,cy);

	}

	override function trigger() {
		super.trigger();
		if( closed )
			open();
		else
			close();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		updateCollisions();
	}

	function updateCollisions() {
		if( level==null || level.destroyed )
			return;

		var set = isAlive() && closed;
		for(i in 0...cWid)
			level.setCollisionOverride(cx+i, cy, set);
	}

	public function open() {
		closed = false;
		level.clearFogUpdateDelay();
		updateCollisions();

		for(y in cy-1...cy+1)
		for(x in cx-2...cx+3)
			level.revealFog(x,y);
	}

	public function close() {
		closed = true;
		updateCollisions();
	}

	override function postUpdate() {
		super.postUpdate();

		if( cd.has("shaking") )
			spr.y += Math.cos(ftime*2)*1 * cd.getRatio("shaking");
	}

	final animSpeed = 0.04;
	override function fixedUpdate() {
		super.fixedUpdate();
		if( !closed && closedFactor>0 ) {
			closedFactor = M.fclamp( closedFactor-animSpeed*data.f_animSpeed, 0, 1 );
			cd.setS("shaking",0.03);
			camera.shakeS(0.3,0.2);
		}
		if( closed && closedFactor<1 ) {
			closedFactor = M.fclamp( closedFactor+animSpeed*data.f_animSpeed*2, 0, 1 );
			cd.setS("shaking",0.03);
			camera.shakeS(0.3,0.2);
		}

		var w = Std.int( M.fmax( wid*0.5*closedFactor, leftDoor.borderLeft+leftDoor.borderRight ) );
		leftDoor.width = w;
		rightDoor.width = w;
		rightDoor.x = wid-w;
	}
}