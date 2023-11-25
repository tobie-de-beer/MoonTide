import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Application.Properties;

var CurLat_Mem = 0;
var CurLon_Mem = 0;
var TideLat_Mem_Settings = 0;
var TideLon_Mem_Settings = 0;
var SunLat_Mem_Settings = 0;
var SunLon_Mem_Settings = 0;
var MoonHemisNorth_Mem_Settings = false;
var DawnFunction_Mem_Settings = false;
var TaskerFunction_Mem_Settings = false;
var newSettings_Mem = false;
var Tides_Mem as Array<Array<Number>> = [[1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1],[1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1]] as Array<Array<Number>>;

var TideLowIndex_Mem = 0;
var TideHighIndex_Mem = 0;
var TaskerData_Mem = "-" as String;
//var TaskerDataRx = false as Boolean;

(:background)
class MoonTideApp extends Application.AppBase {    

    function initialize() {
        //System.println("MoonTideApp.Initialize");          // ########### D E B U G ###############
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        //System.println("MoonTideApp.onStart");              // ########### D E B U G ###############
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        //System.println("MoonTideApp.onStop");               // ########### D E B U G ###############
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        //System.println("MoonTideApp.getInitialView");       // ########### D E B U G ###############
        if(Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(5*60)); // every five minmutes - fastest
        }
        return [ new MoonTideView() ] as Array<Views or InputDelegates>;
    }

    function onBackgroundData(data) {
        //System.println("MoonTideApp.onBackgroundData");     // ########### D E B U G ############### 
        if (data != null) {
            if (data instanceof Array) {
                Application.Storage.setValue("TideData", data); //rather store it!
                for (var i=0;i<2;i+=1) {
                    for (var j=0;j<20;j++) {
                        Tides_Mem[i][j] = data[i][j];
                    }
                }
                Storage.setValue("NeedTides",false); // using mem does not work
                TideLowIndex_Mem = -1;
                Storage.setValue("TideLowIndex",0);
                TideHighIndex_Mem = -1;
                Storage.setValue("TideHighIndex",0);
                // store some stuff just in case OnHide() does not work
                if (Storage.getValue("CurrentLat" != CurLat_Mem)) { //- Minimize writing.
                    Storage.setValue("CurrentLat", CurLat_Mem);
                }
                if (Storage.getValue("CurrentLon" != CurLon_Mem)) { //- Minimize writing.
                    Storage.setValue("CurrentLon", CurLon_Mem);
                }
                TaskerData_Mem = "Tides";
            }   
            if (data instanceof String) {
                TaskerData_Mem = data;
                //TaskerDataRx = true;
            }
        }
    }

    function onSettingsChanged() {
        //System.println("MoonTideApp.onSettingsChanged");    // ########### D E B U G ###############
        // Note: aparently getProperty is using lots of battery power - keep out of onUpdate for WF
        TideLat_Mem_Settings = Properties.getValue("TideLat");
        TideLon_Mem_Settings = Properties.getValue("TideLon");
        SunLat_Mem_Settings = Properties.getValue("SunLat");
        SunLon_Mem_Settings = Properties.getValue("SunLon");
        MoonHemisNorth_Mem_Settings = Properties.getValue("MoonHemisNorth");
        DawnFunction_Mem_Settings = Properties.getValue("DawnFunction");
        // these are used in the background process - currently I cannot access changes on memory - use storage
        TaskerFunction_Mem_Settings = Properties.getValue("TaskerFunction");
        Storage.setValue("TaskerFunction",TaskerFunction_Mem_Settings);
        var TaskerPage = Properties.getValue("TaskerPage");
        Storage.setValue("TaskerPage",TaskerPage);
        var API_Key = Properties.getValue("API_Key");
        Storage.setValue("API_Key",API_Key);

        // the above is also excute onShow - ea start of WF, below is extra to indicate new settings
        Storage.setValue("NeedTides",true);
        newSettings_Mem = true;
    }

    function getServiceDelegate(){
        //System.println("MoonTideApp.getServiceDelegate");   // ########### D E B U G ###############
        return [new MoonTideServiceDelegate()];
    }

    function onAppInstall(){
        //System.println("MoonTideApp.onAppInstall");         // ########### D E B U G ###############
    }
}

function getApp() as MoonTideApp {
    //System.println("MoonTideApp.getApp");                   // ########### D E B U G ###############
    return Application.getApp() as MoonTideApp;
}