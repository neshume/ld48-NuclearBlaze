package gm;

typedef SaveState = {
	var levelId: Null<String>;
	var upgrades : Array<String>;
}

class Save {
	public var state : SaveState;

	public function new() {
		#if hl
			#if debug
			dn.LocalStorage.SUB_FOLDER_NAME = "bin/save";
			#else
			dn.LocalStorage.SUB_FOLDER_NAME = "save";
			#end
		#end

		load();
	}

	function checkSupport() {
		if( dn.LocalStorage.isSupported() )
			return true;
		else {
			trace("Unsupported local storage!");
			return false;
		}
	}

	public function load() {
		if( checkSupport() ) {
			state = dn.LocalStorage.readObject("save",true, getDefault());
			save();
		}
	}

	public function save() {
		if( checkSupport() )
			dn.LocalStorage.writeObject("save",true,state);
	}

	public inline function exists() {
		return state.levelId!=null;
	}

	function getDefault() : SaveState {
		return {
			levelId: null,
			upgrades: [],
		}
	}

	public function clear() {
		state = getDefault();
		save();
	}
}