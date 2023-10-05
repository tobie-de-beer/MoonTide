import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;

(:background)
class MoonTideApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        if(Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(5*60)); // every five minmutes - can´t go faster but should be enought
        }
        return [ new MoonTideView() ] as Array<Views or InputDelegates>;
    }

    function onBackgroundData(data) {
        if (data != null) {
            Application.Storage.setValue("TideData", data);
            Application.Storage.setValue("NeedTides", false);
        }
    }

    function onSettingsChanged() {
        Application.Storage.setValue("NeedTides", true);
    }

    function getServiceDelegate(){
        return [new MoonTideServiceDelegate()];
    }

    function onAppInstall(){
    }
}

function getApp() as MoonTideApp {
    return Application.getApp() as MoonTideApp;
}