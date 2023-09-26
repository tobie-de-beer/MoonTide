import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Math;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Position;


class MoonTideView extends WatchUi.WatchFace {

    var LastCalcTime = Time.now().subtract(new Time.Duration(10000));
    var LastDisplayTime = Time.now().subtract(new Time.Duration(10000));

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void { // screen is 176x176

// #######################################################################
// ## C A L C U L A T I O N S : ##########################################
// #######################################################################

// We work a lot with the current time. use a veraible for it:
        var NowTime = Time.now();

// We only update every 10 min except for steps and stairs
        if (NowTime.compare(LastCalcTime) >= 60) { // only once a minute! except for steps and stairs - see last bit
            var NeedFullDraw = false;
            if (NowTime.compare(LastDisplayTime) >= 10*60) {
                NeedFullDraw = true;
                LastDisplayTime = NowTime;
            }
// During unset and sunrise we actually also do a full draw every minute

// Sanity!
            if (Storage.getValue("TideData") == null) {
                Storage.setValue("TideData", [[1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1],[1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1]]);
            }
            if (Storage.getValue("NeedTides") == null) {
                Storage.setValue("NeedTides", true);
            }
            if (Storage.getValue("CurrentLat") == null) {
                Storage.setValue("CurrentLat",0);
            }
            if (Storage.getValue("CurrentLon") == null) {
                Storage.setValue("CurrentLon",0);
            }

            var TideLat = Properties.getValue("TideLat");
            var TideLon = Properties.getValue("TideLon");
            var SunLat = Properties.getValue("SunLat");
            var SunLon = Properties.getValue("SunLon");
            var CurLat = 0;
            var CurLon = 0;

// check coordinates to use

            if ((TideLat == 100) | (SunLat == 100)){
                if (Activity.getActivityInfo().currentLocation != null){
                    var Cur = Activity.getActivityInfo().currentLocation.toDegrees();
                    CurLat = Cur[0];
                    CurLon = Cur[1];
                    if ((Storage.getValue("CurrentLat") != CurLat) | (Storage.getValue("CurrentLon"))){ // only store if not the same
                        Storage.setValue("CurrentLat", CurLat);
                        Storage.setValue("CurrentLat", CurLat);
                    }
                }
                else {
                    CurLat = Storage.getValue("CurrentLat");
                    CurLon = Storage.getValue("CurrentLon");
                }
            }
            if (TideLat != 100){
                if ((Storage.getValue("Tide_Lat") != TideLat) | (Storage.getValue("Tide_Lon")!=TideLon)) { // only store if not the same
                    Storage.setValue("Tide_Lat",TideLat);
                    Storage.setValue("Tide_Lon",TideLon);
                }
            }
            else {
                if ((Storage.getValue("Tide_Lat") != CurLat) | (Storage.getValue("Tide_Lon")!=CurLon)) { // only store if not the same
                    Storage.setValue("Tide_Lat",CurLat);
                    Storage.setValue("Tide_Lon",CurLon);
                }
            }
            if (SunLat == 100){
                SunLat = CurLat;
                SunLon = CurLon;
            }

// check day night dawn

            var SunPos = new Position.Location( {
                :latitude => SunLat,
                :longitude => SunLon,
                :format => :degrees
            });

            var DayTime = false;
            var Dawn = false;

            var DawnTime = Weather.getSunrise(SunPos, NowTime);
            var DawnSec = NowTime.compare(DawnTime); // Positive is sun is up
            if (DawnSec < -600) { // moring before sunrise
                DayTime = false;
                Dawn = false;
            }
            if ((DawnSec < 600) & (DawnSec >-600)) { // sunrise
                Dawn = true;
                DayTime = false;
            }
            if (DawnSec > 600) { // Day
                Dawn = false;
                DayTime = true;
            }
            DawnTime = Weather.getSunset(SunPos, NowTime);
            DawnSec = DawnTime.compare(NowTime); // Positive is sun is (still) up
            if ((DawnSec < 600) & (DawnSec >-600)){ // sunset
                Dawn = true;
                DayTime = false;
            }
            if (DawnSec < -600 ) { // night
                Dawn = false;
                DayTime = false;
            }

// Tide
// if new tide data was received we need to process that we also set the request for new data here
            var Tides = Storage.getValue("TideData") as Array;
            var TideCheckTime = NowTime.subtract(new Time.Duration(3*60*60)).value();

            var Ti=0;
            while ((TideCheckTime > Tides[0][Ti]) & (Ti<19)) { Ti+=1; }
            if (Ti>2) { Storage.setValue("NeedTides",true); }
            var HighTide = (Tides[0][Ti] - Math.floor(Tides[0][Ti]/(12.0*60*60)))/(12.0*60*60);

            Ti=0;
            while ((TideCheckTime > Tides[1][Ti]) & (Ti<19)) { Ti+=1; }
            if (Ti>2) { Storage.setValue("NeedTides",true); }
            var LowTide = (Tides[1][Ti] - Math.floor(Tides[1][Ti]/(12.0*60*60)))/(12.0*60*60);

// Moon
// set the age of the moon, drawing happens in Graphics
            var ReferenceNewMoonOptions = {
                    :year  => 2023,
                    :month =>    9,
                    :day   =>   15,
                    :hour  =>   01,
                    :minute =>  40
                };
            var ReferenceNewMoon = Time.Gregorian.moment(ReferenceNewMoonOptions);
            var MoonSinceReference = NowTime.compare(ReferenceNewMoon)/60/60/24 / 29.53;
            var MoonNumber =  Math.floor(MoonSinceReference);
            var MoonAge = MoonSinceReference - MoonNumber;

// ########################################################################
// ## G R A P H I C S : ###################################################
// ########################################################################

            if (NeedFullDraw == true) {
                dc.clear();

//Moon
                var MoonR = 23.5;
                var MoonX = 35.5; // added half points makes the maths work nice
                var MoonY = 35;
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
                dc.fillCircle(MoonX, MoonY, MoonR);
                dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                var MoonBlankPoint = [MoonX,MoonY-MoonR]; // top point; 00 xy is left top
                var MoonBlank = [MoonBlankPoint];
                var MoonCut = 0;
                // first down the outside of the moon
                if (MoonAge<=0.5) {
                    for (var i= 9; i>=-10; i-=1) { //64 point limit
                      MoonBlankPoint = [MoonX+MoonR*Math.cos(i*Math.PI/20),MoonY-MoonR*Math.sin(i*Math.PI/20)];
                      MoonBlank.add(MoonBlankPoint);
                    }
                    MoonCut = - Math.cos(MoonAge/0.5*Math.PI);
                    for (var i= -9; i<=9; i+=1) { 
                        MoonBlankPoint = [MoonX+MoonR*Math.cos(i*Math.PI/20)*MoonCut,MoonY-MoonR*Math.sin(i*Math.PI/20)];
                        MoonBlank.add(MoonBlankPoint);
                    }
                }
                else {
                    for (var i= 9; i>=-10; i-=1) { //64 point limit
                      MoonBlankPoint = [MoonX-MoonR*Math.cos(i*Math.PI/20),MoonY-MoonR*Math.sin(i*Math.PI/20)];
                      MoonBlank.add(MoonBlankPoint);
                    }
                    MoonCut = - Math.cos(MoonAge/0.5*Math.PI);
                    for (var i= -9; i<=9; i+=1) { 
                      MoonBlankPoint = [MoonX-MoonR*Math.cos(i*Math.PI/20)*MoonCut,MoonY-MoonR*Math.sin(i*Math.PI/20)];
                      MoonBlank.add(MoonBlankPoint);
                    }
                }
                dc.fillPolygon(MoonBlank);

// Tides

                var TideCirc = 15;
                var TideArc = 35;


                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
                var TideX = 88+TideArc*Math.sin(LowTide*2*Math.PI);
                var TideY = 88-TideArc*Math.cos(LowTide*2*Math.PI);
                dc.drawCircle(TideX, TideY, TideCirc);
                dc.drawText(TideX+1,TideY-1,Graphics.FONT_MEDIUM, "L" , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
                TideX = 88+TideArc*Math.sin(HighTide*2*Math.PI);
                TideY = 88-TideArc*Math.cos(HighTide*2*Math.PI);
                dc.fillCircle(TideX, TideY, TideCirc);
                dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                dc.drawText(TideX+1,TideY-1,Graphics.FONT_MEDIUM, "H" , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

// sun and stars System Stats solarIntensity

                //Dawn = true;
                //DawnSec = -600;
                //var DayTime = true;

                var Light  = 100;
                if (System.getSystemStats().solarIntensity != null) {
                    Light = System.getSystemStats().solarIntensity+1;
                }

                var LightR = 6.0*Math.log(Light,10);

                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
    // day
                if ((DayTime == true) & (Dawn == false)){
                    var SunX = 140;
                    var SunY = 30;
                    dc.fillCircle(SunX, SunY, 8);
                    for (var i=0;i<8;i+=1) {
                        dc.drawLine(SunX + 10*Math.cos(i/4.0*Math.PI+Math.PI/8), SunY + 10*Math.sin(i/4.0*Math.PI+Math.PI/8), 
                            SunX + (10+LightR)*Math.cos(i/4.0*Math.PI+Math.PI/8), SunY + (10+LightR)*Math.sin(i/4.0*Math.PI+Math.PI/8));
                    }

                }
    // night
                if ((DayTime == false) & (Dawn == false)) {
                    var StarX = 130;
                    var StarY =  20;
                    var StarR =   1;
                    dc.drawLine(StarX-StarR, StarY, StarX+StarR+1, StarY);
                    dc.drawLine(StarX, StarY-StarR, StarX, StarY+StarR+1);
                    StarX = 150;
                    StarY =  30;
                    StarR =   2;
                    dc.drawLine(StarX-StarR, StarY, StarX+StarR+1, StarY);
                    dc.drawLine(StarX, StarY-StarR, StarX, StarY+StarR+1);
                    StarX = 160;
                    StarY =  60;
                    StarR =   1;
                    dc.drawLine(StarX-StarR, StarY, StarX+StarR+1, StarY);
                    dc.drawLine(StarX, StarY-StarR, StarX, StarY+StarR+1);
                    StarX = 140;
                    StarY =  40;
                    StarR =   LightR;
                    dc.drawLine(StarX-StarR, StarY, StarX+StarR+1, StarY);
                    dc.drawLine(StarX, StarY-StarR, StarX, StarY+StarR+1);
                }
    //dawn
                if (Dawn == true){
                    dc.drawLine( 140, 70, 176 , 70); // horizon            

                    var SunX = 158-(2*DawnSec/60);
                    var SunY = 70 - (4*DawnSec/60);
                    dc.fillCircle(SunX, SunY, 8);
                    for (var i=0;i<8;i+=1) {
                        dc.drawLine(SunX + 10*Math.cos(i/4.0*Math.PI+Math.PI/8), SunY + 10*Math.sin(i/4.0*Math.PI+Math.PI/8), 
                            SunX + (10+LightR)*Math.cos(i/4.0*Math.PI+Math.PI/8), SunY + (10+LightR)*Math.sin(i/4.0*Math.PI+Math.PI/8));
                    }

                    dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                    dc.fillRectangle(88, 71, 88, 88); // blank below horizon
                }






// Date
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
                dc.fillRoundedRectangle(176-35, 88-15, 34, 31, 3);
                dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                var date = Gregorian.info(NowTime, Time.FORMAT_MEDIUM);
                dc.drawText(176-17,87,Graphics.FONT_LARGE, date.day.toString() , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
                dc.drawText(176-17,120,Graphics.FONT_LARGE, date.day_of_week.toString() , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

// battery
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
                dc.fillRoundedRectangle(0, 88-10, 34, 20, 3);
                dc.fillRoundedRectangle(34, 88-5, 4, 10, 3);
                dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                dc.fillRoundedRectangle(2, 88-8, 30, 16, 2);
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
                dc.fillRoundedRectangle(3, 88-7, 3+25*(System.getSystemStats().battery/100), 14, 1);
                dc.drawText(20,110,Graphics.FONT_MEDIUM, System.getSystemStats().battery.toNumber().toString() + "%" , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

// Always do these..... (even at 1 sec)
// Steps:
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
        dc.drawText(88, 162, Graphics.FONT_LARGE, ActivityMonitor.getInfo().steps.toString() , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

// Stairs:
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
        dc.drawText(88, 14, Graphics.FONT_LARGE, ActivityMonitor.getInfo().floorsClimbed.toString() , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);


        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
