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
	
    function onWebReply(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void { // important to define types here
        var High=0;
        var Low =0;
        var HighTide = [1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1];
        var LowTide =  [1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1];

        if (responseCode == 200) {
            if (data["copyright"] != null ) {
                var FirstTide = data["extremes"][0]["type"];
                if (FirstTide.equals("High")) {
                    High=0;
                    Low=1;
//System.println("First is High");
                }
                else {
                    High=1;
                    Low=0;
//System.println("First is Low");
                }
                for (var i=0; i<40; i+=2){
                    HighTide[i/2] = (data["extremes"][i+High]["dt"]);
                    LowTide[i/2] = (data["extremes"][i+Low]["dt"]);
                }
                Background.exit([HighTide,LowTide]);
            }
        }
    }

    function onTemporalEvent() {
        // if connected...:
//System.println("onTemporalEvent\n");
        if (Storage.getValue("NeedTides") == true) {
            Communications.makeWebRequest(
                "https://www.worldtides.info/api/v3",
                { "extremes" => "true",
                  "lat"      => Storage.getValue("Tide_Lat"),
                  "lon"      => Storage.getValue("Tide_Lon"),
                  "days"     => "11",
                  "key"      => Properties.getValue("API_Key"),
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
