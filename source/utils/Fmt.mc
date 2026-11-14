import Toybox.Lang;

module Fmt {

    // 3420 -> "3,420", 10000 -> "10,000".
    function thousands(n as Number) as String {
        var neg = n < 0;
        var v = neg ? -n : n;
        var s = "";
        while (v >= 1000) {
            s = "," + (v % 1000).format("%03d") + s;
            v = v / 1000;
        }
        return (neg ? "-" : "") + v.toString() + s;
    }

    // XP change with sign: 100 -> "+100", -50 -> "-50".
    function signed(n as Number) as String {
        return (n > 0 ? "+" : "") + n.toString();
    }
}
