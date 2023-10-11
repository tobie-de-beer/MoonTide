import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Math;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Application.Storage;
import Toybox.Application.Properties;


class MoonTideView extends WatchUi.WatchFace {

    // stuff to keep in memory
    var TideLat_Mem_Settings = 0;
    var TideLon_Mem_Settings = 0;
    var SunLat_Mem_Settings = 0;
    var SunLon_Mem_Settings = 0;
    var SunLat_Mem = 0;
    var SunLon_Mem = 0;
    var CurLat_Mem = 0;
    var CurLon_Mem = 0;
    var SunRise_Mem;
    var SunSet_Mem;

    var NeedNewSunRiseSet_Mem = true;
    var Today_Mem = Time.today().subtract(new Time.Duration(1000000)).value();

//    var LastCalcTime_Mem = Time.now().subtract(new Time.Duration(10000));
    var LastCalcTime_Mem = Time.now().subtract(new Time.Duration(10000)).value() as Lang.Number;
//    var LastDisplayTime_Mem = Time.now().subtract(new Time.Duration(10000));
    var LastDisplayTime_Mem = Time.now().subtract(new Time.Duration(10000)).value() as Lang.Number;
    var SolarArray_Mem as Array<Lang.Number> = [1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1] as Array<Lang.Number>;
    var SolarInd_Mem = 0;
    var CloseToDawn_Mem = true;
    // var MoonS_Mem = true;

    function initialize() {
        WatchFace.initialize();
        //System.println("MoonTideView.Initialize");               // ########### D E B U G ###############          
    }


    // Load your resources here
    function onLayout(dc as Dc) as Void {
        //System.println("MoonTideView.onLayout");                 // ########### D E B U G ###############
        //setLayout(Rez.Layouts.WatchFace(dc));
    }

    function interpretSettings() as Void {
        //System.println("MoonTideView.interpretSettings");        // ########### D E B U G ###############
        TideLat_Mem_Settings = Properties.getValue("TideLat");
        TideLon_Mem_Settings = Properties.getValue("TideLon");
        SunLat_Mem_Settings = Properties.getValue("SunLat");
        SunLon_Mem_Settings = Properties.getValue("SunLon");
        if (TideLat_Mem_Settings == 100) {
            Storage.setValue("TideLat",CurLat_Mem); // using mem does not work in bg
            Storage.setValue("TideLon",CurLon_Mem);  // using mem does not work in bg
        }
        else {
            Storage.setValue("TideLat",TideLat_Mem_Settings);  // using mem does not work in bg
            Storage.setValue("TideLon",TideLon_Mem_Settings);   // using mem does not work in bg
        }
        if (SunLat_Mem_Settings == 100){
            SunLat_Mem = CurLat_Mem;
            SunLon_Mem = CurLon_Mem;
        }
        else {
            SunLat_Mem = SunLat_Mem_Settings;
            SunLon_Mem = SunLon_Mem_Settings;
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        //System.println("MoonTideView.onShow");            
    // populate memory

    //Sanity:
        if (Storage.getValue("TideData") == null) {
            Storage.setValue("TideData", [[1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1],[1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1]]);
        }
        if (Storage.getValue("CurrentLat") == null) {
            Storage.setValue("CurrentLat",0);
        }
        if (Storage.getValue("CurrentLon") == null) {
            Storage.setValue("CurrentLon",0);
        }
        if (Storage.getValue("NeedTides") == null) {
            Storage.setValue("NeedTides",true);
        }

        // Settings:
        CurLat_Mem = Storage.getValue("CurrentLat");
        CurLon_Mem = Storage.getValue("CurrentLon");
        Tides_Mem = Storage.getValue("TideData") as Array<Array<Number>>;
        interpretSettings();
    }


    // Update the view
    function onUpdate(dc as Dc) as Void { // screen is 176x176
        //System.println("MoonTideView.onUpdate");                  // ########### D E B U G ###############            

// #######################################################################
// ## C A L C U L A T I O N S : ##########################################
// #######################################################################

// We work a lot with the current time. use a veraible for it:
        var NowTime = Time.now();
        var NowTimeVal = NowTime.value() as Lang.Number; // use this wherever possible time routines seems more expensive than simple subtraction.
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK); // Every Section should return to this. Changing color takes significant proccessing time


// We only update every 10 min except for steps and stairs
 //       if (NowTime.compare(LastCalcTime_Mem) >= 60) { // only once a minute! except for steps and stairs - see last bit
        if (NowTimeVal - LastCalcTime_Mem >= 60) { // only once a minute! except for steps and stairs - see last bit
            LastCalcTime_Mem = NowTimeVal;
            //System.println("MoonTideView.onUpdate_1min");         // ########### D E B U G ###############            

            var NeedFullDraw = false;
            
//            if (NowTime.compare(LastDisplayTime_Mem) >= 10*60) {
            if (NowTimeVal - LastDisplayTime_Mem >= 10*60) {
                NeedFullDraw = true;
                LastDisplayTime_Mem = NowTimeVal;
                //System.println("MoonTideView.onUpdate_10Min");    // ########### D E B U G ###############            
            }
// During unset and sunrise we actually also do a full draw every minute

            if (newSettings_Mem == true){
                interpretSettings();
                newSettings_Mem = false;
                Storage.setValue("NeedTides",true); // using mem does not work in bg
                NeedFullDraw = true;
            }

// Solar -- always (every minute)
            var Solar  = 40;
            if (System.getSystemStats().solarIntensity != null) {
                Solar = System.getSystemStats().solarIntensity;
            }
            SolarArray_Mem[SolarInd_Mem] = Solar;
            SolarInd_Mem += 1;
            if (SolarInd_Mem >= 20) {
                SolarInd_Mem = 0;
            }

// check coordinates to use
            var DayTime = false;
            var Dawn = false;
            var DawnSec = 0;

            if ((CloseToDawn_Mem == true) | (NeedFullDraw == true)) { // only when neccesary

                if ((TideLat_Mem_Settings == 100) | (SunLat_Mem_Settings == 100)){
                    if (Activity.getActivityInfo().currentLocation != null){
//System.println("Found Required Position");
                        var Cur = Activity.getActivityInfo().currentLocation.toDegrees();
                        var CurLat = Cur[0];
                        var CurLon = Cur[1];
                        if ((CurLat_Mem != CurLat) | (CurLon_Mem != CurLon)){ // only store if not the same
                            CurLat_Mem = CurLat;
                            CurLon_Mem = CurLon;
                            if (TideLat_Mem_Settings == 100){ 
                                //NeedTided_Mem = true; // should actully request new tides... but concerned about battery and data
                                Storage.setValue("TideLat",CurLat); // using mem does not work in bg
                                Storage.setValue("TideLon",CurLon); // using mem does not work in bg
                            }
                            if (SunLat_Mem_Settings == 100){
                                SunLat_Mem = CurLat;
                                SunLon_Mem = CurLon;
                                NeedNewSunRiseSet_Mem = true;
                            }
                        }
                    }
                }

// check day night dawn

                CloseToDawn_Mem = false;

                var Today = Time.today().value();
                if ((Today != Today_Mem) | (NeedNewSunRiseSet_Mem == true)){ // reduce unneccesary calls
                    Today_Mem = Today;
                    NeedNewSunRiseSet_Mem = false;
                    var SunPos = new Position.Location( {
                        :latitude => SunLat_Mem,
                        :longitude => SunLon_Mem,
                        :format => :degrees
                    });
                    SunRise_Mem = Weather.getSunrise(SunPos, NowTime).value();
                    SunSet_Mem = Weather.getSunset(SunPos, NowTime).value();
                }

                var DawnTime = SunRise_Mem;
                var DawnSecEval = NowTimeVal - DawnTime; // Positive is sun is up
                if (DawnSecEval < -600) { // moring before sunrise
                    DayTime = false;
                    Dawn = false;
                }
                if ((DawnSecEval <= 600) & (DawnSecEval >= -600)) { // sunrise
                    Dawn = true;
                    DayTime = false;
                    DawnSec = DawnSecEval;
                }
                if ((DawnSecEval <= 660) & (DawnSecEval >= -1200)) { // close to sunrise
                    CloseToDawn_Mem = true;
                }
                if (DawnSecEval > 600) { // Day
                    Dawn = false;
                    DayTime = true;
                }
                DawnTime = SunSet_Mem;
                DawnSecEval = DawnTime - NowTimeVal; // Positive is sun is (still) up
                if ((DawnSecEval <= 600) & (DawnSecEval >= -600)){ // sunset
                    Dawn = true;
                    DayTime = false;
                    DawnSec = DawnSecEval;
                }
                if ((DawnSecEval < 1200) & (DawnSecEval >-660)) { // close to sunset
                    CloseToDawn_Mem = true;
                }
                if (DawnSecEval < -600 ) { // night
                    Dawn = false;
                    DayTime = false;
                }
                if (Dawn == true){
                    NeedFullDraw = true;
                }
            } // if ((CloseToDawn_Mem == true) | (NeedFullDraw == true))



            if (NeedFullDraw == true) { // the following only happens every 10 min! (or at Dawn)

// Tide
// if new tide data was received we need to process that we also set the request for new data here
                //var TideCheckTime = NowTime.subtract(new Time.Duration(3*60*60)).value();
                var TideCheckTime = NowTimeVal - (3*60*60);
            
                //var TidePos = new Position.Location( {
                //    :latitude => TideLat,
                //    :longitude => TideLon,
                //    :format => :degrees
                //);

                //var TideTimeOffsetNow = Time.Gregorian.localMoment(TidePos,NowTime);

                var TideTimeOffset = System.getClockTime().timeZoneOffset;

                var NeedTides = false;

                var Ti=0;
                while ((TideCheckTime > Tides_Mem[0][Ti]) & (Ti<19)) { Ti+=1; }
                if (Ti>2) { NeedTides = true; } 
                var Tide = (Tides_Mem[0][Ti] + TideTimeOffset)/(12.0*60*60);
                var HighTide = Tide - Math.floor(Tide); // 0 to one as around the clock once => 12 hr

                Ti=0;
                while ((TideCheckTime > Tides_Mem[1][Ti]) & (Ti<19)) { Ti+=1; }
                if (Ti>2) { NeedTides = true; } 
                Tide = (Tides_Mem[1][Ti] + TideTimeOffset)/(12.0*60*60);
                var LowTide = Tide - Math.floor(Tide);

                if (NeedTides == true) {  // using mem does not work in bg 
                    if (Storage.getValue("NeedTides") == false) { //- Minimize writing.
                        Storage.setValue("NeedTides",true); 
                    }
                }
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

                dc.clear();

//Moon
                var MoonR = 23.5;
                var MoonX = 35.5; // added half points makes the maths work nice
                var MoonY = 35;
                dc.fillCircle(MoonX, MoonY, MoonR);
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
                dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                dc.fillPolygon(MoonBlank); // ##### BLACK #####
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK); // Back to normal

// sun and stars System Stats solarIntensity

                //Dawn = true;
                //DawnSec = -600;
                //var DayTime = true;
                var SolarLight = 0;
                for (var i =0; i<20; i+=1){
                    SolarLight += SolarArray_Mem[i];
                }

// not working well                var Ray = (3.0*Math.log(SolarLight+1.0,10)).toNumber()+1;
                var Ray = 2;
                if (SolarLight >0) { Ray = 3;}
                if (SolarLight >1) { Ray = 4;}
                if (SolarLight >2) { Ray = 5;}
                if (SolarLight >4) { Ray = 6;}
                if (SolarLight >8) { Ray = 7;}
                if (SolarLight >16) { Ray = 8;}
                if (SolarLight >32) { Ray = 9;}
                if (SolarLight >64) { Ray = 10;}
                if (SolarLight >128) { Ray = 11;}
                if (SolarLight >256) { Ray = 12;}
                if (SolarLight >512) { Ray = 13;}
                if (SolarLight >1024) { Ray = 14;}

    // day
                if ((DayTime == true) & (Dawn == false)){
                    var SunX = 140;
                    var SunY = 30;
                    dc.fillCircle(SunX, SunY, 8);
                    for (var i=0;i<8;i+=1) {
                        dc.drawLine(SunX + 10*Math.cos(i/4.0*Math.PI+Math.PI/8), SunY + 10*Math.sin(i/4.0*Math.PI+Math.PI/8), 
                            SunX + (10+Ray)*Math.cos(i/4.0*Math.PI+Math.PI/8), SunY + (10+Ray)*Math.sin(i/4.0*Math.PI+Math.PI/8));
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
                    StarR =   Ray;
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
                            SunX + (10+Ray)*Math.cos(i/4.0*Math.PI+Math.PI/8), SunY + (10+Ray)*Math.sin(i/4.0*Math.PI+Math.PI/8));
                    }

                    dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                    dc.fillRectangle(88, 71, 88, 88); // blank below horizon // ##### BLACK #####
                    dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK); // Back to normal
                }

// Tides note: need to be after sun and stars - possible interference with below horizon stuff

                var TideCirc = 15;
                var TideArc = 35;


                var TideX = 88+TideArc*Math.sin(LowTide*2*Math.PI);
                var TideY = 88-TideArc*Math.cos(LowTide*2*Math.PI);
                dc.drawCircle(TideX, TideY, TideCirc);
                dc.drawText(TideX+1,TideY-1,Graphics.FONT_MEDIUM, "L" , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
                TideX = 88+TideArc*Math.sin(HighTide*2*Math.PI);
                TideY = 88-TideArc*Math.cos(HighTide*2*Math.PI);
                dc.fillCircle(TideX, TideY, TideCirc);
                dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                dc.drawText(TideX+1,TideY-1,Graphics.FONT_MEDIUM, "H" , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER); // ##### BLACK #####
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK); // Back to normal

// Date note: need to be after sun and stars due to belo horizon blank
                dc.fillRoundedRectangle(140, 88-15, 34, 31, 3);
                var date = Gregorian.info(NowTime, Time.FORMAT_MEDIUM);
                dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                dc.drawText(158,87,Graphics.FONT_LARGE, date.day.toString() , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER); // ##### BLACK #####
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK); // Back to normal
                dc.drawText(155,120,Graphics.FONT_LARGE, date.day_of_week.toString() , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

// battery
                dc.fillRoundedRectangle(2, 88-10, 34, 20, 3);
                dc.fillRoundedRectangle(36, 88-5, 4, 10, 3);
                dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                dc.fillRoundedRectangle(4, 88-8, 30, 16, 2); // ##### BLACK #####
                dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK); // Back to normal
                dc.fillRoundedRectangle(5, 88-7, 3+25*(System.getSystemStats().battery/100), 14, 1);
                dc.drawText(20,110,Graphics.FONT_MEDIUM, System.getSystemStats().battery.toNumber().toString() + "%" , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            } // if (NeedFullDraw == true) 

// stuff for every minute....

        } //if (NowTime.compare(LastCalcTime_Mem) >= 60)

// Always do these..... (even at 1 sec)
// Steps:
        dc.drawText(88, 162, Graphics.FONT_LARGE, ActivityMonitor.getInfo().steps.toString() , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

// Stairs:
        dc.drawText(88, 14, Graphics.FONT_LARGE, ActivityMonitor.getInfo().floorsClimbed.toString() , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);


        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        //System.println("MoonTideView.onHide");           // ########### D E B U G ###############         
        if (Storage.getValue("CurrentLat" != CurLat_Mem)) { //- Minimize writing.
            Storage.setValue("CurrentLat", CurLat_Mem);
        }
        if (Storage.getValue("CurrentLon" != CurLon_Mem)) { //- Minimize writing.
            Storage.setValue("CurrentLon", CurLon_Mem);
        }
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        //System.println("MoonTideView.onExitSleep");      // ########### D E B U G ###############            
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        //System.println("MoonTideView.onEnterSleep");     // ########### D E B U G ###############            
    }

}
