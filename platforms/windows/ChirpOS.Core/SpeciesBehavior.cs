namespace ChirpOS.Core;
public static class SpeciesBehavior {
    public static string? Frame(string id,double age,bool side=false) {
        if(id=="greatSpottedWoodpecker" && side){var t=age%12;return t>4 && t<5.6?"peck"+((int)(t*12)%2):"cling0";}
        if(id=="nightHeron"){var t=age%53;if(t>31 && t<32)return "poop"+((int)((t-31)*6)%2);if(t>20 && t<22)return "stretch";if(t>40 && t<41)return (int)(t*8)%2==0?"shake":"stand";return t%7>6.8?"blink":"stand";}
        if(id is "greyHeron" or "littleEgret" or "chinesePondHeron"){var t=age%23;return t>16 && t<18?"idle"+((int)t%2):(t>20 && t<21?"preen0":"stand");}
        var (interval,rate)=id switch {
            "plumbeousWaterRedstart" or "redFlankedBluetail" or "blackDrongo" => (5d,4d),
            "commonKestrel" or "peregrineFalcon" or "blackKite" or "commonBuzzard" => (14d,1d),
            "eurasianWoodcock" => (6d,3d),
            "swinhoesWhiteEye" or "yellowBrowedWarbler" or "vinousThroatedParrotbill" or "greatTit" => (5d,5d),
            "mallard" or "commonMoorhen" or "eurasianCoot" => (12d,2d),
            "redWhiskeredBulbul" or "treeSparrow" or "lightVentedBulbul" or "spottedDove" or "chineseBlackbird" or "magpieRobin" or "longTailedShrike" => (0d,0d),
            _ => (9d,2d)
        };
        if(interval==0)return null;var c=age%interval;
        if(c>2 && c<4)return "idle"+((int)(c*rate)%2);
        if(c>interval-1.4 && c<interval-.4)return "preen"+((int)(c*4)%2);
        return c<.15?"blink":((int)(age*1.2)%2==0?"stand":"breathe");
    }
}
