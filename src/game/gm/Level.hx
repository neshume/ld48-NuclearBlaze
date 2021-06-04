package gm;

@:enum abstract Prop(Int) {
	var Oil = 1;
	var StopFire = 2;
}

class Level extends dn.Process {
	var game(get,never) : Game; inline function get_game() return Game.ME;
	var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	/** Level grid-based width**/
	public var cWid(get,never) : Int; inline function get_cWid() return data.l_Collisions.cWid;

	/** Level grid-based height **/
	public var cHei(get,never) : Int; inline function get_cHei() return data.l_Collisions.cHei;

	/** Level pixel width**/
	public var pxWid(get,never) : Int; inline function get_pxWid() return cWid*Const.GRID;

	/** Level pixel height**/
	public var pxHei(get,never) : Int; inline function get_pxHei() return cHei*Const.GRID;

	public var data : World_Level;
	var tilesetSource : h2d.Tile;

	var collOverride : Map<Int,Bool> = new Map();
	var marks : Map< LevelMark, Map<Int,Bool> > = new Map();
	public var fireStates : Map<Int,FireState> = new Map();
	var invalidated = true;

	public var fogRender : h2d.SpriteBatch;
	var fogReveals : Map<Int,Float> = new Map();
	var fogElements : Map<Int, h2d.SpriteBatch.BatchElement> = new Map();
	var fogCx = 0;
	var fogCy = 0;
	var fogWid : Int;
	var fogHei : Int;
	public var fireCount(default,null) = Const.INFINITE;

	var sky : Null<h2d.Bitmap>;


	public function new(ldtkLevel:World.World_Level) {
		super(Game.ME);

		createRootInLayers(Game.ME.scroller, Const.DP_BG);
		data = ldtkLevel;
		tilesetSource = hxd.Res.atlas.world.toAseprite().toTile();


		var dirs = [-1, 1];
		for(cy in 0...data.l_Collisions.cHei)
		for(cx in 0...data.l_Collisions.cWid) {
			// Init marks
			if( hc(cx,cy) ) {
				if( !hc(cx,cy+1) || !hc(cx,cy-1) || !hc(cx-1,cy) || !hc(cx+1,cy) )
					setMark(WallEdge, cx,cy);

				if( !hc(cx+1,cy+1) || !hc(cx+1,cy-1) || !hc(cx-1,cy-1) || !hc(cx-1,cy+1) )
					setMark(WallEdge, cx,cy);
			}

			if( !hc(cx,cy) && hc(cx+1,cy) )
				setMark(WallToRight, cx, cy);

			if( !hc(cx,cy) && hc(cx-1,cy) )
				setMark(WallToLeft, cx, cy);

			if( !hc(cx,cy) && ( hc(cx+1,cy) || hc(cx-1,cy) || hc(cx,cy+1) || hc(cx,cy-1) ) )
				setMark(NearCollision, cx,cy);

			if( !hc(cx,cy) && !hc(cx,cy-1) ) {
				if( hc(cx+1,cy) && !hc(cx+1,cy-1) )
					setMark(EdgeGrabToRight, cx,cy);
				if( hc(cx-1,cy) && !hc(cx-1,cy-1) )
					setMark(EdgeGrabToLeft, cx,cy);
			}

			if( !hc(cx,cy) && hc(cx,cy+1) ) {
				if( !hc(cx+1,cy+1) || hc(cx+1,cy) )
					setMark(PlatformEndRight, cx,cy);
				if( !hc(cx-1,cy+1) || hc(cx-1,cy) )
					setMark(PlatformEndLeft, cx,cy);
			}

			if( !hc(cx,cy) && hc(cx,cy+1) && !hc(cx,cy-1) )
				for(d in dirs) {
					if( hc(cx+d,cy) ) {
						if( !hc(cx+d,cy-1) )
							setMark(AutoJump1, cx,cy);
						else if( !hc(cx+d,cy-2) && !hc(cx,cy-2) )
							setMark(AutoJump2, cx,cy);
					}
				}

			// Init fire spots
			if( !hasAnyCollision(cx,cy) ) {
				if( cx<=0 || cy<=0 || cx>=cWid-1 || cy>=cHei-1 )
					continue;

				if( hasProperty(cx,cy,StopFire) )
					continue;

				if( hasAnyCollision(cx,cy+1) && !hasProperty(cx,cy+1,StopFire) )
					fireStates.set( coordId(cx,cy), new FireState() );
				else if( ( hasAnyCollision(cx-1,cy) && !hasProperty(cx-1,cy,StopFire) || hasAnyCollision(cx+1,cy) && !hasProperty(cx+1,cy,StopFire) ) )
					fireStates.set( coordId(cx,cy), new FireState() );

				// Properties
				if( hasFireState(cx,cy) ) {
					if( hasProperty(cx, cy+1, Oil) )
						getFireState(cx,cy).oil = true;
				}
			}
		}

		fogRender = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(fogRender, Const.DP_FOG);
		fogRender.visible = !game.kidMode;
		buildFog();
	}

	override function onResize() {
		super.onResize();
		buildFog();

		if( sky!=null ) {
			sky.setScale(Const.SCALE);
			sky.y = h() - sky.tile.height*Const.SCALE;
		}
	}

	public function hasProperty(cx:Int, cy:Int, prop:Prop) {
		return isValid(cx,cy) ? data.l_Props.hasValue(cx,cy, cast prop) : false;
	}

	override function onDispose() {
		super.onDispose();

		fogRender.remove();
		fogRender = null;
		// fogState = null;

		for(fs in fireStates)
			fs.dispose();
		fireStates = null;

		if( sky!=null ) {
			sky.remove();
			sky = null;
		}

		data = null;
		tilesetSource = null;
		marks = null;
	}

	function buildFog() {
		fogElements = new Map();
		fogRender.clear();
		fogWid = M.ceil( game.camera.getRawPxWid()/Const.GRID ) + 3;
		fogHei = M.ceil( game.camera.getRawPxHei()/Const.GRID ) + 3;
		var t = Assets.tiles.getTile( Assets.tilesDict.fxFog );
		t.setCenterRatio();
		for(cy in 0...fogHei)
		for(cx in 0...fogWid) {
			var be = new h2d.SpriteBatch.BatchElement(t);
			fogElements.set( fogCoordId(cx,cy), be );
			fogRender.add(be);
			be.x = (cx+0.5)*Const.GRID; // overridden in updateFog()
			be.y = (cy+0.5)*Const.GRID;
			C.colorizeBatchElement(be, 0x0);
		}
		clearFogUpdateDelay();
	}


	inline function fogCoordId(cx,cy) {
		return cx + cy*fogWid;
	}

	/** TRUE if given coords are in level bounds **/
	public inline function isValid(cx,cy) return cx>=0 && cx<cWid && cy>=0 && cy<cHei;

	/** Gets the integer ID of a given level grid coord **/
	public inline function coordId(cx,cy) return cx + cy*cWid;

	/** Ask for a level render that will only happen at the end of the current frame. **/
	public inline function invalidate() {
		invalidated = true;
	}

	/** Return TRUE if mark is present at coordinates **/
	public inline function hasMark(mark:LevelMark, cx:Int, cy:Int) {
		return !isValid(cx,cy) || !marks.exists(mark) ? false : marks.get(mark).exists( coordId(cx,cy) );
	}

	/** Enable mark at coordinates **/
	public function setMark(mark:LevelMark, cx:Int, cy:Int) {
		if( isValid(cx,cy) && !hasMark(mark,cx,cy) ) {
			if( !marks.exists(mark) )
				marks.set(mark, new Map());
			marks.get(mark).set( coordId(cx,cy), true );
		}
	}

	/** Show a mark in level, for debug purpose **/
	public function debugMark(m:LevelMark) {
		for(cy in 0...cHei)
		for(cx in 0...cWid)
			if( hasMark(m, cx,cy) )
				game.fx.markerCase(cx,cy, 99);
	}

	/** Remove mark at coordinates **/
	public function removeMark(mark:LevelMark, cx:Int, cy:Int) {
		if( isValid(cx,cy) && hasMark(mark,cx,cy) )
			marks.get(mark).remove( coordId(cx,cy) );
	}

	public function setCollisionOverride(cx,cy, coll:Null<Bool>) {
		if( isValid(cx,cy) )
			if( coll!=null )
				collOverride.set( coordId(cx,cy), coll );
			else
				collOverride.remove( coordId(cx,cy) );
	}

	// Alias
	inline function hc(x,y) return hasAnyCollision(x,y);

	inline function isWallCollisionValue(intGrid:Int) {
		return intGrid==1 || intGrid==4 || intGrid==5;
	}

	/** Return TRUE if "Collisions" layer contains a collision value **/
	public inline function hasAnyCollision(cx,cy) : Bool {
		return !isValid(cx,cy)
			? true
			: collOverride.exists(coordId(cx,cy))
				? collOverride.get(coordId(cx,cy))
				: isWallCollisionValue( data.l_Collisions.getInt(cx,cy) ) || data.l_Collisions.getInt(cx,cy)==2;
	}

	/** Return TRUE if "Collisions" layer contains a WALL collision value **/
	public inline function hasWallCollision(cx,cy) : Bool {
		return !isValid(cx,cy)
			? true
			: collOverride.exists(coordId(cx,cy))
				? collOverride.get(coordId(cx,cy))
				: isWallCollisionValue( data.l_Collisions.getInt(cx,cy) );
	}

	/** Return TRUE if "Collisions" layer contains a ONE WAY collision value **/
	public inline function hasOneWay(cx,cy) : Bool {
		return !isValid(cx,cy) ? false : data.l_Collisions.getInt(cx,cy)==2;// || hasLadder(cx,cy) && !hasLadder(cx,cy-1) && !hasAnyCollision(cx,cy-1);
	}

	/** Return TRUE if "Collisions" layer contains a GRASS collision value **/
	public inline function hasGrass(cx,cy) : Bool {
		return !isValid(cx,cy) ? false : data.l_Collisions.getInt(cx,cy)==4;
	}

	/** Return TRUE if "Collisions" layer contains a LADDER collision value **/
	public inline function hasLadder(cx,cy) : Bool {
		return !isValid(cx,cy) ? false : data.l_Collisions.getInt(cx,cy)==3;
	}

	/** Render current level**/
	function render() {
		root.removeChildren();

		if( data.hasBgImage() ) {
			var bg = data.getBgBitmap();
			root.addChild(bg);
		}

		// Sky "box"
		if( sky!=null ) {
			sky.remove();
			sky = null;
		}
		if( data.f_isGameMenu ) {
			sky = new h2d.Bitmap( hxd.Res.atlas.skyBg.toAseprite().toTile() );
			game.root.add(sky, Const.DP_BG);
		}

		var tg = new h2d.TileGroup(tilesetSource, root);
		data.l_BgWalls.render(tg);
		data.l_BgTiles.render(tg);
		data.l_Collisions.render(tg);
		data.l_MainTiles2.render(tg);
		data.l_MainTiles1.render(tg);
		data.l_Pipes.render(tg);
		data.l_Wires.render(tg);
		data.l_FrontTiles.render(tg);
		data.l_Props_tiles.render(tg);

		dn.Process.resizeAll();
	}

	public inline function hasFireState(cx,cy) {
		return !destroyed && isValid(cx,cy) && fireStates.exists( coordId(cx,cy) );
	}

	public inline function getFireState(cx,cy, createIfMissing=false) : Null<FireState> {
		return hasFireState(cx,cy)
			? fireStates.get( coordId(cx,cy) )
			: createIfMissing
				? {
					var fs = new FireState();
					fireStates.set( coordId(cx,cy), fs );
					fs;
				}
				: null;
	}

	public inline function isBurning(cx,cy) {
		return !destroyed && hasFireState(cx,cy) && fireStates.get( coordId(cx,cy) ).isBurning();
	}

	public inline function getFireLevel(cx,cy) {
		return isBurning(cx,cy) ? getFireState(cx,cy).level : 0;
	}

	public inline function decreaseFire(cx,cy, ratio:Float) {
		if( isBurning(cx,cy) )
			getFireState(cx,cy).decrease(ratio);
	}

	public inline function ignite(cx,cy, startLevel=0, startProgress=0., ignoreControl=false) : Bool {
		if( !hasFireState(cx,cy) )
			return false;
		else if( !hasAnyCollision(cx,cy) && ( ignoreControl || !getFireState(cx,cy).isUnderControl() ) ) {
			var fs = getFireState(cx,cy);
			if( fs.isBurning() )
				return true;
			else {
				fs.ignite(startLevel, startProgress);
				if( fs.oil ) {
					fs.level = 1;
					fs.lr = 0.5;
					ignite(cx-1,cy);
					ignite(cx+1,cy);
					fx.oilIgnite(cx,cy);
				}
				return true;
			}
		}
		else
			return false;

	}

	override function postUpdate() {
		super.postUpdate();

		// Level render
		if( invalidated ) {
			invalidated = false;
			render();
		}

		// Fire fx
		if( !cd.hasSetS("flames",0.4) ) {
			var smoke = !cd.hasSetS("flamesSmoke",0.4);
			var fs : FireState = null;
			for(cy in 0...data.l_Collisions.cHei)
			for(cx in 0...data.l_Collisions.cWid) {
				if( Game.ME.camera.isOnScreenCase(cx,cy,32) && hasFireState(cx,cy) ) {
					fs = getFireState(cx,cy);
					if( fs.isBurning() ) {
						fx.levelFlames(cx, cy, fs, fs.strongFx);
						if( isFogRevealed(cx,cy) && !hasAnyCollision(cx,cy-1) )
							fx.levelFireSparks(cx, cy, fs);


						if( smoke && hasAnyCollision(cx,cy+1) )
							fx.levelFireSmoke(cx, cy, fs);
					}
					else if( fs.extinguished ) {
						if( smoke && hasAnyCollision(cx,cy+1) )
							fx.levelExtinguishedSmoke((cx+0.5)*Const.GRID, (cy+1)*Const.GRID, fs, fs.smokePower, fs.smokeColor);
					}
				}
			}
		}

		updateFog();
	}

	public inline function isFogRevealed(cx,cy) {
		return fogReveals.exists( coordId(cx,cy) );
	}

	public inline function revealFogArea(cx,cy, radius:Int) {
		dn.Bresenham.iterateDisc(cx,cy, radius, (x,y)->revealFog(x,y));
	}

	public inline function revealFog(cx,cy, immediate=false, allowRecursion=true) {
		if( !isFogRevealed(cx,cy) ) {
			fogReveals.set( coordId(cx,cy), immediate ? 1 : 0.33 );

			if( allowRecursion ) {
				// Wall edges
				for(oy in -1...2)
				for(ox in -1...2)
					if( hasMark(WallEdge, cx+ox,cy+oy) && !isFogRevealed(cx+ox,cy+oy) )
						revealFog(cx+ox,cy+oy, immediate, false);

				// Doors
				if( hasMark(VDoorZone,cx+1,cy) ) revealFog(cx+1,cy, immediate, false);
				if( hasMark(VDoorZone,cx-1,cy) ) revealFog(cx-1,cy, immediate, false);

				// Doors
				if( hasMark(HDoorZone,cx,cy-1) ) revealFog(cx,cy-1, immediate, false);
				if( hasMark(HDoorZone,cx,cy+1) ) revealFog(cx,cy+1, immediate, false);
			}
		}
	}

	public inline function clearFogUpdateDelay() {
		cd.unset("fogPierce");
	}

	function updateFog() {
		// Position fog
		fogCx = Std.int(game.camera.left/Const.GRID)-1;
		fogCy = Std.int(game.camera.top/Const.GRID)-1;
		fogRender.x = fogCx*Const.GRID;
		fogRender.y = fogCy*Const.GRID;

		// Pierce
		if( !cd.hasSetS("fogPierce",0.3) ) {
			var h = game.hero;
			dn.Bresenham.iterateDisc(game.hero.cx, game.hero.cy, 8, (x,y)->{
				if( !isFogRevealed(x,y) && ( h.sightCheck(x,y) || h.sightCheckFree(h.cx+h.dir, h.cy, x,y) ) )
					revealFog(x,y);

				// Small floating pieces
				if( !isFogRevealed(x,y) && isFogRevealed(x-1,y) && isFogRevealed(x+1,y) )
					revealFog(x,y);
				if( !isFogRevealed(x,y) && isFogRevealed(x,y-1) && isFogRevealed(x,y+1) )
					revealFog(x,y);
			});
		}

		// Display
		var r = 0.;
		for(oy in 0...fogHei)
		for(ox in 0...fogWid) {
			var be = fogElements.get( fogCoordId(ox,oy) );
			if( isFogRevealed( fogCx+ox, fogCy+oy ) ) {
				r = fogReveals.get( coordId(fogCx+ox, fogCy+oy) );
				r = M.fmin( r+Const.db.FogRevealAnimSpeed*tmod, 1 );
				fogReveals.set( coordId(fogCx+ox, fogCy+oy), r );
				be.alpha = 1-r;
				be.visible = r<1;
			}
			else {
				be.alpha = 1;
				be.visible = true;
				be.x = (ox+0.5)*Const.GRID;
				if( hasMark(DoorToLeft, fogCx+ox, fogCy+oy) )
					be.x += 8;
				else if( hasMark(DoorToRight, fogCx+ox, fogCy+oy) )
					be.x -= 8;
			}
		}
	}

	public function canSeeThrough(cx,cy) {
		return isValid(cx,cy) && ( !hasWallCollision(cx,cy) || data.l_Collisions.getInt(cx,cy)==5 );
	}
	inline function sighCheck(x1,y1,x2,y2) {
		return dn.Bresenham.checkThinLine(x1,y1, x2,y2, canSeeThrough);
	}


	public function suspendFireForS(t:Float) {
		cd.setS("fireSuspended", t);
	}

	public inline function isFireSuspended() {
		return cd.has("fireSuspended") || game.camera.hasCinematicTracking();
	}

	function updateFire() {
		fireCount = 0;

		for(e in gm.en.FireSpray.ALL)
			if( e.isActive() )
				fireCount++;

		var fs : FireState = null;
		var rangeX = Std.int(Const.db.FirePropagationRange);
		var rangeY = Std.int(Const.db.FirePropagationRange);

		for(cy in 0...data.l_Collisions.cHei)
		for(cx in 0...data.l_Collisions.cWid) {
			if( hasFireState(cx,cy) ) {
				fs = getFireState(cx,cy);

				if( fs.isBurning() && !fs.magic )
					fireCount++;

				if( isFireSuspended() )
					continue;

				// Increase
				if( fs.isBurning() && !fs.isUnderControl() ) {
					fs.increase( Const.db.FireIncPerTick);
					if( fs.oil ) {
						ignite(cx-1,cy, 1);
						ignite(cx+1,cy, 1);
					}
				}

				// Update cooldown
				if( fs.propgationCdS>0 )
					fs.propgationCdS -= Const.db.FireTick;

				// Update underControlness
				if( fs.underControlS>0 )
					fs.underControlS -= Const.db.FireTick;

				// Try to propagate
				if( !game.kidMode && !fs.isUnderControl() && fs.isMaxed() && fs.propgationCdS<=0 && fs.propagates )
					if( Std.random(100) < Const.db.FirePropagationChance*100 ) {
						fs.propgationCdS = game.camera.isOnScreenCase(cx,cy) ? Const.db.FirePropagationCd : Const.db.FirePropagationCdOffScreen;
						for(y in cy-rangeY...cy+rangeY+1)
						for(x in cx-rangeX...cx+rangeX+1)
							if( sighCheck(cx,cy, x,y) ) {
								ignite(x,y);
								if( fs.magic && hasFireState(x,y) )
									getFireState(x,y).magic = true;
							}
					}
			}
		}
	}

	override function update() {
		super.update();

		// Fire update
		if( !cd.hasSetS("fireTick",Const.db.FireTick) )
			updateFire();
	}
}