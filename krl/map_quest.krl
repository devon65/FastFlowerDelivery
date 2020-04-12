ruleset map_quest {
    meta {
        configure using consumer_key = ""
        provides get_lat_long, get_address_dist
    }
    global {

        // calculate_address_distance = function(address1, address2){
        //     latlong1 = get_lat_long(address1)
        //     latlong2 = get_lat_long(address2)
        //     return calculate_distance(latlong1{"lat"}, latlong1{"lng"}, latlong2{"lat"}, latlong2{"lng"})
        // }

        // //this crazy function is found at https://www.movable-type.co.uk/scripts/latlong.html
        // calculate_distance = function(lat1, long1, lat2, long2){
        //     R = 6371000 //earth's radius in meters
        //     miles_per_kilometer = 0.6213709999975146
        //     lat1_rad = math:deg2rad(lat1)
        //     lat2_rad = math:deg2rad(lat2)
        //     delta_lat_rad = math:deg2rad(lat2 - lat1)
        //     delta_long_rad = math:deg2rad(long2 - long1)

        //     a = math:power(math:sin(delta_lat_rad/2), 2) + 
        //         (math:cos(lat1_rad) * math:cos(lat2_rad) *
        //         math:power(math:sin(delta_long_rad/2), 2))

        //     a_min = math:sqrt(a) < 1 => math:sqrt(a) | 1
        //     c = 2 * math:asin(a_min)

        //     d = R * c
        //     return (d.klog("Kilometers: ") * miles_per_kilometer).klog("Miles: ")
        // }

        get_address_dist = function(from_address, to_address) {
            url = <<https://www.mapquestapi.com/directions/v2/route?key=#{consumer_key}&from=#{from_address}&to=#{to_address}>>
            result = http:get(url){"content"}.decode()
            result{["route", "distance"]}
        }

        get_lat_long = function(address){
            url = <<http://www.mapquestapi.com/geocoding/v1/address?key=#{consumer_key}&location=#{address}>>
            result = http:get(url){"content"}.decode()
            result{"results"}[0]{"locations"}[0]{"latLng"}
        }
    }
}