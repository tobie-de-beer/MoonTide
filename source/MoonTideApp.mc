import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Application.Properties;

var newSettings_Mem = false;
var Tides_Mem as Array<Array<Number>> = [[1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1],[1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1]] as Array<Array<Number>>;

(:background)
class MoonTideApp extends Application.AppBase {    

    function initialize() {
        AppBase.initialize();
        // System.println("MoonTideApp.Initialize");          // ########### D E B U G ###############
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
            Background.registerForTemporalEvent(new Time.Duration(5*60)); // every five minmutes - can´t go faster but should be enought
        }
        return [ new MoonTideView() ] as Array<Views or InputDelegates>;
    }

    function onBackgroundData(data) {
        //System.println("MoonTideApp.onBackgroundData");     // ########### D E B U G ############### 
        if (data != null) {
            Application.Storage.setValue("TideData", data); //rather store it!
            Tides_Mem = data;
            Storage.setValue("NeedTides",false); // using mem does not work
        }
    }

    function onSettingsChanged() {
        //System.println("MoonTideApp.onSettingsChanged");    // ########### D E B U G ###############
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