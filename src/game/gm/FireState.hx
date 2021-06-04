package gm;

class FireState {
	public static final MAX = 2;

	public var level = 0;
	public var lr = 0.; // level ratio

	public var propgationCdS = 0.;
	public var underControlS = 0.;
	public var superS = 0.;
	public var resistance(default,set) = 0.;
	public var strongFx = false;
	public var propagates = true;

	public var extinguished = false;
	public var oil = false;
	public var magic = false;
	public var infinite = false;
	public var smokePower = 1.0;
	public var smokeColor : Null<Int>;

	public inline function new() {}

	inline function set_resistance(v) {
		return resistance = M.fclamp(v,0,1);
	}

	@:keep
	public function toString() {
		return 'FS:$level>${Std.int(lr*100)}%';
	}

	public inline function isUnderControl() {
		return underControlS>0;
	}

	public inline function control(ignoreResist=false, multiplier=1.0) {
		underControlS = Const.db.ControlDuration * ( ignoreResist ? 1 : 1-resistance ) * multiplier;
	}

	public inline function getPowerRatio(step=false) {
		return step
			? level/MAX
			: ( level + M.fmin(lr,0.99) ) / MAX;
	}

	public inline function getRatio() {
		return ( level + M.fmin(lr,0.99) ) / (MAX+1);
	}

	public inline function isBurning() {
		return level>0 || lr>0;
	}

	public inline function isMaxed() {
		return level>=MAX;
	}

	public function ignite(startLevel=0, startProgress=0.) {
		if( !isBurning() || level<startLevel) {
			level = startLevel;
			lr = M.fmax(startProgress, 0.01);
		}
	}

	public function setToMin() {
		level = 0;
		lr = 0.1;
	}

	public inline function clear() {
		level = 0;
		lr = 0;
	}

	public inline function increase(ratio:Float) {
		lr+=ratio;
		while( lr>=1 )
			if( level>=MAX ) {
				lr = 1;
				break;
			}
			else {
				level++;
				lr--;
			}
	}

	public inline function decrease(ratio:Float, ignoreResist=false) {
		lr -= ignoreResist ? ratio : (1-resistance) * ratio;
		while( lr<0 )
			if( level<=0 ) {
				lr = 0;
				break;
			}
			else {
				level--;
				lr++;
			}
	}

	public function dispose() {}
}