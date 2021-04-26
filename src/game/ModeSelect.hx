class ModeSelect extends dn.Process {
	var ca : ControllerAccess;
	var f : h2d.Flow;
	public function new() {
		super(App.ME);
		ca = App.ME.controller.createAccess("mode", true);
		createRootInLayers( App.ME.root, Const.DP_UI );

		f = new h2d.Flow(root);
		f.verticalSpacing = 2;
		f.layout = Vertical;

		text("Select mode", "#ffcc00");
		f.addSpacing(4);
		text("1 - Normal", "#ffffff");
		text("2 - Kid friendly", "#ffffff");
	}

	function text(str:String, col:String) {
		var tf = new h2d.Text(Assets.fontPixel, f);
		tf.text = str;
		tf.textColor = C.hexToInt(col);
		return tf;
	}

	override function onResize() {
		super.onResize();
		f.setScale(Const.SCALE);
		f.x = Std.int( w()*0.5 - f.outerWidth*f.scaleX*0.5 );
		f.y = Std.int( h()*0.5 - f.outerHeight*f.scaleY*0.5 );
	}

	override function onDispose() {
		super.onDispose();
		ca.dispose();
		ca = null;
	}

	override function update() {
		super.update();

		#if hl
		if( ca.isKeyboardPressed(K.ESCAPE) )
			App.ME.exit();
		#end

		if( ca.isKeyboardPressed(K.NUMBER_1) || ca.isKeyboardPressed(K.NUMPAD_1) ) {
			App.ME.startGame(false);
			destroy();
		}
		else if( ca.isKeyboardPressed(K.NUMBER_2) || ca.isKeyboardPressed(K.NUMPAD_2) ) {
			App.ME.startGame(true);
			destroy();
		}
	}
}