using Toybox.Background;
using Toybox.System;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Application.Properties;
using Toybox.Application.Storage;

// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system.

(:background)
class MoonTideServiceDelegate extends Toybox.System.ServiceDelegate {
	
	function initialize() {
		System.ServiceDelegate.initialize();
	}
	
    function onWebReply(responseCode as Lang.Number, data as Lang.Dictionary) as Void { // important to define types here
System.println("Web Response %s\n" + responseCode.toString());
        var High=0;
        var Low =0;
        var HighTide = [1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1];
        var LowTide =  [1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1];

        if (responseCode == 200) {
            if ((data["extremes"][0]["type"] == "High") | (data["extremes"][1]["type"] == "Low")) {
                High=0;
                Low=1;
                System.println("First is High\n");
            }
            else {
                High=1;
                Low=0;
                System.println("First is Low\n");
            }
            for (var i=0; i<40; i+=2){
                HighTide[i/2] = (data["extremes"][i+High]["dt"]);
                LowTide[i/2] = (data["extremes"][i+Low]["dt"]);
            }
            Background.exit([HighTide,LowTide]);
        }
    }

    function onTemporalEvent() {
        // if connected...:
        System.println("onTemporalEvent\n");
        if (Storage.getValue("NeedTides") == true) {
            Communications.makeWebRequest(
                "https://www.worldtides.info/api/v3",
                { "extremes" => "true",
                  "lat"      => Storage.getValue("Tide_Lat"),//"-28.125",
                  "lon"      => Storage.getValue("Tide_Lon"),//"32.560",
                  "days"     => "11",
                  "key"      => Properties.getValue("API_Key"),//"04286f5a-dfdb-4c4e-86c3-6f6f84de2e00"
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
    }    

}
