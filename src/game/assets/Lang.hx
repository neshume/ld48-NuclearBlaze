package assets;

import dn.data.GetText;

class Lang {
    static var _initDone = false;
    static var DEFAULT = "en";
    public static var CUR = "??";
    public static var t : GetText;

    public static function init(?lid:String) {
        if( _initDone )
            return;

        _initDone = true;
        CUR = lid==null ? DEFAULT : lid;

		t = new GetText();
		t.readMo( hxd.Res.load("lang/"+CUR+".mo").entry.getBytes() );
    }

    public static function untranslated(str:Dynamic) : LocaleString {
        init();
        return t.untranslated(str);
    }



	public static function parseText(str:String) : String {
        str = Lib.trimEmptyLines(str);
		str = StringTools.replace(str, "%%", Std.string(Const.db.SCP_ID));
		str = StringTools.replace(str, "%n", Std.string(Const.db.SCP_Report_Pages));
        return str;
	}
}