using Toybox.Background;
using Toybox.Application;
using Toybox.System;
using Toybox.Communications;
using Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Application.Properties;

// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system.

(:background)
class MoonTideServiceDelegate extends Toybox.System.ServiceDelegate {
	
	function initialize() {
		System.ServiceDelegate.initialize();
        //System.println("MoonTideBackground.Initialize");    // ########### D E B U G ###############
	}
	
    function onWebReply(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void { // important to define types here
        //System.println("MoonTideBackground.onWebReply");    // ########### D E B U G ###############
        var High=0;
        var Low =0;
        var HighTide = [1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1];
        var LowTide =  [1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1];

        if (responseCode == 200) {
            if (data instanceof Dictionary) {
                if (data["copyright"] != null ) {
                    var Tides  = data.get("extremes") as Lang.Array<Lang.Dictionary>;
                    //var FirstTide = data["extremes"][0]["type"];
                    var FirstTide = Tides[0]["type"];
                    if (FirstTide.equals("High")) {
                        High=0;
                        Low=1;
                        //System.println("First is High"); // ########### D E B U G ###############
                    }
                    else {
                        High=1;
                        Low=0;
                        //System.println("First is Low"); // ########### D E B U G ###############
                    }
                    for (var i=0; i<40; i+=2){
                        //HighTide[i/2] = data["extremes"][i+High]["dt"];
                        HighTide[i/2] = Tides[i+High]["dt"];
                        //LowTide[i/2] = data["extremes"][i+Low]["dt"];
                        LowTide[i/2] = Tides[i+Low]["dt"];
                    }
                    var Reply = {
                        "Text" => "$Tides$",
                        "Tides" => [HighTide,LowTide]
                    };
                    Background.exit(Reply);
                }
                else {
                        var Reply = {
                            "Text" => "$Null$",
                            "Tides" => [HighTide,LowTide]
                        };
                        Background.exit(Reply);
                }
            }
            else {
                if (data instanceof String) {
                    if (data.length() < 10) {
                        var Reply = {
                            "Text" => data,
                            "Tides" => [HighTide,LowTide]
                        };
                        Background.exit(Reply);
                    }
                }
                else {
                        var Reply = {
                            "Text" => "$Null$",
                            "Tides" => [HighTide,LowTide]
                        };
                        Background.exit(Reply);
                }
            }
        }
        else {
            Background.exit(null);
        }
    }

    function onTemporalEvent() {
        //System.println("MoonTideBackground.onTemporalEvent");    // ########### D E B U G ###############    
        var Tide = [1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1];
        if (System.getDeviceSettings().connectionAvailable == true) { //System.getDeviceSettings().connectionInfo connectionAvailable phone connected
            System.println("MoonTideBackgroun.onTemporalEvent.WebRequest\n");    // ########### D E B U G ###############
            if (Storage.getValue("NeedTides") == true) { // cant'read memory :-( )
                Communications.makeWebRequest(
                    "https://www.worldtides.info/api/v3",
                    { "extremes" => "true",
                      "lat"      => Storage.getValue("TideLat"), // cant'read memory :-( )
                      "lon"      => Storage.getValue("TideLon"), // cant'read memory :-( )
                      "days"     => "11",
                      "key"      => Storage.getValue("API_Key"), // cant'read memory :-( )
                    },
                    {
                        :headers => {                                          
                           "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                        },
                        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                    },
                    method(:onWebReply)
                );
            }
            else {
                Communications.makeWebRequest(
                    "http://127.0.0.1:1821/MoonTide",
                    {
                    },
                    {
                        :headers => {                                          
                           "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                        },
                        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
                    },
                    method(:onWebReply)
                );
            }
        }
        else {
            var Reply = {
                "Text" => "$Null$",
                "Tides" => [Tide,Tide]
            };
            Background.exit(Reply);
        }
    }    

}
