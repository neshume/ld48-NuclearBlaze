package ui;

class Document extends dn.Process {
	public static var ME : Document = null;

	var game(get,never) : Game; inline function get_game() return Game.ME;
	var dict = Assets.tilesDict;

	var ca : ControllerAccess;
	var docWid : Int;
	var docHei : Int;
	var data : Entity_Document;

	public function new(data:Entity_Document) {
		super(game);
		if( ME!=null )
			ME.destroy();
		ME = this;

		this.data = data;
		ca = App.ME.controller.createAccess("doc",true);

		createRootInLayers(Game.ME.root, Const.DP_UI);

		var t = switch data.f_style {
			case WhitePaper,SCP_report:
				hxd.Res.atlas.doc_whitePaper.toAseprite().toTile();

			case DarkPaper:
				hxd.Res.atlas.doc_darkPaper.toAseprite().toTile();
		}
		t.setCenterRatio(0.5,1);
		docWid = t.iwidth;
		docHei = t.iheight;

		var bg = new h2d.Bitmap( t, root );
		dn.Process.resizeAll();

		var px = 15;
		var py = 15;

		var flow = new h2d.Flow(root);
		flow.layout = Vertical;
		flow.x = Std.int( -docWid*0.5+px );
		flow.y = Std.int( -docHei+py );
		flow.horizontalAlign = Middle;

		// Header wrapper
		var header = new h2d.Flow(flow);
		header.horizontalAlign = Left;
		header.verticalAlign= Middle;
		header.maxWidth = header.minWidth = docWid-px*2;
		header.visible = false;

		var htf = new h2d.Text(Assets.fontPixel, header);
		htf.lineSpacing = Const.db.PixelFontLineSpacing;
		htf.maxWidth = docWid-px*2;
		htf.textColor = data.f_headerColor_int;

		// Header separator
		flow.addSpacing(4);
		var line = Assets.tiles.h_get(dict.pixel, flow);
		line.colorize(data.f_headerColor_int);
		line.scaleX = docWid-px*2;
		line.alpha = 0.3;
		flow.addSpacing(4);

		// Header text
		if( data.f_header!=null ) {
			htf.text = Lang.parseText( data.f_header );
			header.visible = true;
		}

		// Main text
		var tf = new h2d.Text(Assets.fontPixel, flow);
		tf.lineSpacing = Const.db.PixelFontLineSpacing;
		tf.text = Lang.parseText( data.f_text );
		tf.maxWidth = docWid-px*2;
		tf.textColor = data.f_textColor_int;

		// Style effect
		switch data.f_style {
			case WhitePaper:
			case DarkPaper:
			case SCP_report:
				var logo = Assets.tiles.getBitmap(dict.docScp, header);
				header.getProperties(logo).horizontalAlign = Right;
				htf.maxWidth-=logo.tile.width;
		}

		// Override using file content
		if( data.f_sourceFile_bytes!=null ) {
			var raw = data.f_sourceFile_bytes.getString(0, data.f_sourceFile_bytes.length, UTF8);
			var idReg = ~/^#\s+([a-z0-9_]+)/gim;
			while( idReg.match(raw) ) {
				var id = idReg.matched(1);
				if( id==data.f_sourceId ) {
					var blockReg = new EReg("# "+id+"(.*?)(\\z|^#)", "gmis");
					if( blockReg.match(raw) ) {
						var parts = blockReg.matched(1).split("---");
						if( parts.length==1 )
							tf.text = Lang.parseText(parts[0]);
						else {
							header.visible = true;
							htf.text = Lang.parseText(parts[0]);
							tf.text = Lang.parseText(parts[1]);
						}
						break;
					}
				}
				raw = idReg.matchedRight();
			}
		}

		flow.reflow();

		tw.createS(root.x, root.x+30*Const.SCALE > root.x, 0.3);
		tw.createS(root.y, root.y+50*Const.SCALE > root.y+1, 0.3);
		tw.createS(root.alpha, 0>1, TEaseIn, 0.1);
		tw.createS(root.rotation, 0.4>0, TEaseOut, 0.3);
		tw.createS(root.scaleY, 0>root.scaleY, TEaseOut, 0.3);
	}

	public static function closeAny() {
		if( ME!=null )
			ME.destroy();
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.SCALE);
		root.x = Std.int( 0.5*w() );
		root.y = h();
	}

	override function onDispose() {
		super.onDispose();
		ca.dispose();
		ca = null;
		if( ME==this )
			ME = null;
	}

	function close() {
		ca.lock();
		tw.createS(root.rotation, -0.1, TEaseIn, 0.2);
		tw.createS(root.y, root.y+50*Const.SCALE, TEaseIn, 0.2);
		tw.createS(root.scaleY, 0, TEaseIn, 0.2).onEnd = destroy;
		game.delayer.addS( onClose, data.f_closeCallbackDelay);
		onClose();
	}

	public dynamic function onClose() {}

	override function postUpdate() {
		super.postUpdate();
	}

	override function update() {
		super.update();

		if( ca.isKeyboardPressed(K.ESCAPE) || ca.aPressed() || ca.bPressed() || ca.xPressed() )
			close();
	}

}