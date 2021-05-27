package gm.en.int;

class Door extends Entity {
	public static var ALL : Array<Door> = [];
	public var closed(default,null) = true;
	var cHei = 0;

	public var kicks = 0;
	public var requiredItem : Null<Enum_Items>;
	public var data : Entity_Door;

	public function new(d:Entity_Door) {
		super(d.cx,d.cy);
		data = d;
		triggerId = data.f_triggerId;
		revealFogOnTrigger = true;
		ALL.push(this);
		Game.ME.scroller.add(spr, Const.DP_BG);
		requiredItem = d.f_requiredItem;
		collides = false;
		gravityMul = 0;

		kicks = d.f_requireLevelComplete || d.f_requiredItem!=null || triggerId>=0 ? 0 : d.f_kicks;
		cHei = M.round(d.height / Const.GRID);
		hei = cHei*Const.GRID;
		closed = !d.f_opened;
		updateCollisions();
		for(y in cy-cHei+1...cy+1)
			level.setMark(VDoorZone, cx,y);

		for(i in 0...cHei) {
			level.setMark(DoorToLeft, cx+1, cy-i);
			level.setMark(DoorToRight, cx-1, cy-i);
		}
	}

	override function trigger() {
		super.trigger();
		if( closed ) {
			fx.doorOpened(attachX, attachY, cHei*Const.GRID, -dirTo(hero));
			open( -dirTo(hero) );
		}
	}

	public static function getAt(cx,cy) {
		for(e in ALL)
			if( e.isAlive() && cx==e.cx && cy>e.cy-e.cHei && cy<=e.cy )
				return e;
		return null;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		updateCollisions();
	}

	function updateCollisions() {
		if( isAlive() ) {
			if( data.f_requireLevelComplete )
				spr.set( closed ? dict.exitClosed : dir==1 ? dict.exitOpenedRight : dict.exitOpenedLeft);
			else if( data.f_requiredItem==GreenCard)
				spr.set( closed ? dict.greenDoorClosed: dict.greenDoorOpened );
			else if( data.f_requiredItem==BlueCard)
				spr.set( closed ? dict.blueDoorClosed: dict.blueDoorOpened );
			else if( data.f_triggerId>=0 || data.f_requiredItem!=null )
				spr.set( closed ? dict.triggerDoorClosed : dict.triggerDoorOpened );
			else
				spr.set( closed ? dict.doorClosed : dict.doorOpened );
			spr.setCenterRatio(closed ? 0.5 : 0, 1);
		}

		if( level==null || level.destroyed )
			return;

		var set = isAlive() && closed;
		for(i in 0...cHei)
			level.setCollisionOverride(cx, cy-i, set);
	}

	public function open(openDir=1) {
		closed = false;
		dir = openDir;
		level.clearFogUpdateDelay();
		updateCollisions();

		for(y in cy-1...cy+1)
		for(x in cx-2...cx+3)
			level.revealFog(x,y);

		if( requiredItem!=null )
			hero.sayBubble( Assets.getItem(requiredItem), Assets.tilesDict.emoteOk, 0x83c359);


		// Check if there are fires behind
		var bigFires = 0;
		if( data.f_canExplode )
			dn.Bresenham.iterateDisc(cx,cy,4, (x,y)->{
				if( openDir==1 && x<=cx || openDir==-1 && x>=cx )
					return;
				if( level.getFireLevel(x,y)==2 && sightCheck(x,y) )
					bigFires++;
			});

		// Explodes!
		if( bigFires>=2 ) {
			game.addSlowMo("doorExplosion", 1, 0.2);
			game.stopFrame();

			game.heat = 1;
			fx.flashBangS(0xff8800, 0.6, 0.3);
			fx.doorExplosion(centerX, centerY, -openDir);

			hero.bump(dirTo(hero)*0.2, -0.1);
			hero.cd.setS("shield",0.75);
			if( !game.hasUpgrade(UpShield) )
				hero.kill(this);

			dn.Bresenham.iterateDisc(cx,cy,6, (x,y)->{
				if( level.hasFireState(x,y) && !level.isBurning(x,y) && sightCheck(x,y) ) {
					var fs = level.getFireState(x,y);
					fs.underControlS = 0;
					level.ignite(x,y, 1, 0.7);
				}
			});
			return true;
		}
		else
			return false;
	}

	override function postUpdate() {
		super.postUpdate();

		// Prevent Exit door flipping
		if( data.f_requireLevelComplete ) {
			spr.scaleX =  sprScaleX * sprSquashX;
			if( !closed && dir==-1 )
				spr.x-=16;
		}

		if( closed && !cd.hasSetS("blink",1) ) {
			blink(0x996600);
			cd.setS("keepBlink",0.1);
			blinkFrict = 0.8;
		}
	}

	public function close() {
		closed = true;
		updateCollisions();

		for(e in Entity.ALL) {
			if( e==this || !e.isAlive() )
				continue;

			if( e.cx==cx && e.cy>cy-cHei && e.cy<=cy ) {
				if( e.xr<0.5 ) {
					e.cx--;
					e.xr = 0.9;
				}
				else {
					e.cx++;
					e.xr = 0.1;
				}
				e.onPosManuallyChanged();
			}
		}
	}
}