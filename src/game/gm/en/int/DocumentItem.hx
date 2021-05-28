package gm.en.int;

class DocumentItem extends Entity {
	public static var ALL : Array<DocumentItem> = [];

	var data : Entity_Document;
	var g : h2d.Graphics;
	var holdS = 0.;
	var callbackDone = false;

	public function new(d:Entity_Document) {
		super(0,0);
		ALL.push(this);
		data = d;
		setPosPixel(d.pixelX, d.pixelY);
		setPivots(d.pivotX, d.pivotY);
		gravityMul = 0;
		collides = false;

		spr.set(dict.document);
		Game.ME.scroller.add(spr, Const.DP_BG);

		g = new h2d.Graphics();
		game.scroller.add(g,Const.DP_UI);
		g.blendMode = Add;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();

		g.setPosition(centerX, centerY);

		if( isOnScreenCenter() ) {
			if( !cd.has("read") && !cd.hasSetS("blink",1) )
				blink(0xa8d9ff);
		}
	}


	public static function getBest(by:Entity) : Null<DocumentItem> {
		var dh = new dn.DecisionHelper(ALL);
		dh.keepOnly( e->by.distCase(e)<=2 );
		dh.score( (e)->-e.distCase(by) );
		dh.score( (e)->e.cx==by.cx && e.cy==by.cy ? 3 : 0 );
		dh.score( (e)->by.dirTo(e)==by.dir ? 1 : 0 );
		return dh.getBest();
	}


	function read() {
		var d = new ui.Document(data);
		if( !callbackDone && data.f_triggerIdAfterRead>=0 ) {
			callbackDone = true;
			d.onClose = ()->{
				for(e in Entity.ALL)
					if( e.triggerId==data.f_triggerIdAfterRead && e.isAlive() )
						e.trigger();
			}
		}
	}


	public function hold() {
		holdS+=1/Const.FIXED_UPDATE_FPS;
		cd.setS("maintain",0.1);
		if( holdS>=Const.db.DocumentHoldTimeS) {
			holdS = Const.db.DocumentHoldTimeS;
			read();
		}
		updateProgress();
	}

	function updateProgress() {
		g.clear();
		g.beginFill(0xa8d9ff, 0.4);
		g.drawPieInner(0,0, 20,17, -M.PIHALF, M.PI2 * M.fclamp(holdS/Const.db.DocumentHoldTimeS, 0, 1));
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		if( !cd.has("maintain") ) {
			holdS *= 0.7;
			if( holdS<=0.1 )
				holdS = 0;
			updateProgress();
		}
	}
}