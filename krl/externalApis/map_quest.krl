ruleset map_quest {
    meta {
        configure using consumer_key = ""
        provides get_lat_long, get_address_dist
    }
    global {

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