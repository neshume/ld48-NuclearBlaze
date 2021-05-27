package ui;

class Document extends dn.Process {
	var game(get,never) : Game; inline function get_game() return Game.ME;
	var dict = Assets.tilesDict;

	var ca : ControllerAccess;
	var docWid : Int;
	var docHei : Int;

	public function new(data:Entity_Document) {
		super(game);

		ca = App.ME.controller.createAccess("doc",true);

		createRootInLayers(Game.ME.root, Const.DP_UI);

		var t = hxd.Res.atlas.paper.toAseprite().toTile();
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

		// Header text
		var htf = new h2d.Text(Assets.fontPixel, header);
		if( data.f_header!=null ) {
			htf.lineSpacing = -6;
			htf.text = Assets.parseText( data.f_header );
			htf.maxWidth = docWid-px*2;
			htf.textColor = data.f_headerColor_int;

			flow.addSpacing(4);
			var line = Assets.tiles.h_get(dict.pixel, flow);
			line.colorize(data.f_headerColor_int);
			line.scaleX = docWid-px*2;
			line.alpha = 0.3;
			flow.addSpacing(4);
		}
		else
			htf.visible = false;

		// Main text
		var tf = new h2d.Text(Assets.fontPixel, flow);
		tf.lineSpacing = -6;
		tf.text = Assets.parseText( data.f_text );
		tf.maxWidth = docWid-px*2;
		tf.textColor = data.f_textColor_int;

		// Style effect
		switch data.f_style {
			case WhitePaper:
			case SCP_report:
				var logo = Assets.tiles.getBitmap(dict.docScp, header);
				header.getProperties(logo).horizontalAlign = Right;
				htf.maxWidth-=logo.tile.width;
		}

		flow.reflow();

		tw.createS(root.x, root.x+30*Const.SCALE > root.x, 0.3);
		tw.createS(root.y, root.y+50*Const.SCALE > root.y, 0.3);
		tw.createS(root.alpha, 0>1, TEaseIn, 0.1);
		tw.createS(root.rotation, 0.4>0, TEaseOut, 0.3);
		tw.createS(root.scaleY, 0>root.scaleY, TEaseOut, 0.3);
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
	}

	function close() {
		ca.lock();
		tw.createS(root.rotation, -0.1, TEaseIn, 0.2);
		tw.createS(root.y, root.y+50*Const.SCALE, TEaseIn, 0.2);
		tw.createS(root.scaleY, 0, TEaseIn, 0.2).onEnd = destroy;
	}

	override function postUpdate() {
		super.postUpdate();
	}

	override function update() {
		super.update();

		if( ca.isKeyboardPressed(K.ESCAPE) || ca.aPressed() || ca.bPressed() || ca.xPressed() )
			close();
	}

}