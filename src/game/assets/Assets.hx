package assets;

import dn.heaps.slib.*;

/**
	This class centralizes all assets management (ie. art, sounds, fonts etc.)
**/
class Assets {
	// Fonts
	public static var fontPixel : h2d.Font;
	public static var fontTiny : h2d.Font;
	public static var fontSmall : h2d.Font;
	public static var fontMedium : h2d.Font;
	public static var fontLarge : h2d.Font;

	/** Main atlas **/
	public static var tiles : SpriteLib;
	public static var hero : SpriteLib;

	/** Fully typed access to slice names present in Aseprite file (eg. `trace(tilesDict.myStoneTexture)` )**/
	public static var tilesDict = dn.heaps.assets.Aseprite.getDict(hxd.Res.atlas.tiles);

	/** LDtk world data **/
	public static var worldData : World;


	static var _initDone = false;
	public static function init() {
		if( _initDone )
			return;
		_initDone = true;

		// Fonts
		fontPixel = hxd.Res.fonts.pixel_unicode_regular_12.toFont();
		fontTiny = new hxd.res.BitmapFont( hxd.Res.fonts.saira_extracondensed_thin_10_xml.entry ).toFont();
		fontSmall = new hxd.res.BitmapFont( hxd.Res.fonts.saira_extracondensed_light_14_xml.entry ).toFont();
		fontMedium = new hxd.res.BitmapFont( hxd.Res.fonts.saira_extracondensed_extralight_24_xml.entry ).toFont();
		fontLarge = new hxd.res.BitmapFont( hxd.Res.fonts.saira_extracondensed_extralight_48_xml.entry ).toFont();

		// build sprite atlas directly from Aseprite file
		tiles = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.tiles.toAseprite());
		tiles.defineAnim("fxExplode","0(2),1-6");
		tiles.defineAnim("upHalo", "0-4, 5(10)");
		tiles.defineAnim("fxHeliWings", "0-7");
		tiles.defineAnim("fxWaterPhong", "0-5");
		tiles.defineAnim("waterAmmoSurface", "0-7");
		hero = dn.heaps.assets.Aseprite.convertToSLib(Const.FPS, hxd.Res.atlas.hero.toAseprite());

		// CastleDB file hot reloading
		#if debug
		hxd.Res.data.watch(function() {
			// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
			App.ME.delayer.cancelById("cdb");
			App.ME.delayer.addS("cdb", function() {
				CastleDb.load( hxd.Res.data.entry.getBytes().toString() );
				Const.fillCdbValues();
				if( Game.exists() )
					Game.ME.onDbReload();
			}, 0.2);
		});
		#end

		// Parse castleDB JSON
		CastleDb.load( hxd.Res.data.entry.getText() );
		Const.fillCdbValues();

		// `const.json` hot-reloading
		hxd.Res.const.watch(function() {
			// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
			App.ME.delayer.cancelById("constJson");
			App.ME.delayer.addS("constJson", function() {
				Const.fillJsonValues( hxd.Res.const.entry.getBytes().toString() );
				if( Game.exists() )
					Game.ME.onDbReload();
			}, 0.2);
		});

		// LDtk init & parsing
		worldData = new World();

		// LDtk file hot-reloading
		#if debug
		var res = try hxd.Res.load(worldData.projectFilePath.substr(4)) catch(_) null; // assume the LDtk file is in "res/" subfolder
		if( res!=null )
			res.watch( ()->{
				// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
				App.ME.delayer.cancelById("ldtk");
				App.ME.delayer.addS("ldtk", function() {
					worldData.parseJson( res.entry.getText() );
					if( Game.exists() )
						Game.ME.onLdtkReload();
				}, 0.2);
			});
		#end
	}


	public static function parseText(str:String) : String {
		return StringTools.replace(str, "%%", Std.string(Const.db.SCP_ID));
	}

	public static function getItem(e:Enum_Items) : h2d.Tile {
		if( !tiles.exists("item"+e.getName()) )
			return h2d.Tile.fromColor(0xff0000,16,16); // error
		else
			return tiles.getTile("item"+e.getName());
	}


	public static function update(tmod) {
		tiles.tmod = tmod;
		hero.tmod = tmod;
		if( Game.exists() && Game.ME.isPaused() )
			hero.tmod = 0;
		// <-- add other atlas TMOD updates here
	}

}