ruleset test_apis {
    meta {
        use module twilio_v2 alias twilio
            with account_sid = keys:twilio{"account_sid"}
                auth_token =  keys:twilio{"auth_token"}
        
        use module map_quest alias map_quest
            with consumer_key = keys:map_quest{"consumer_key"}

    }

    rule test_send_sms {
        select when test new_message
        twilio:send_sms(event:attr("to"),
                        event:attr("from"),
                        event:attr("message"))
    }

    rule test_get_messages {
        select when test get_messages
        pre {
            content = twilio:get_messages(event:attr("To").klog("To: "),
                                        event:attr("From").klog("From: "),
                                        event:attr("PageSize").klog("PageSize: "),
                                        event:attr("Page").klog("Page: "),
                                        event:attr("PageToken").klog("Page Token: "))
        }
        send_directive("say", {"data":content})
    }

    rule test_get_lat_long {
        select when test get_lat_long
        pre{
            content = map_quest:get_lat_long(event:attr("address"))
        }
        send_directive("say", {"data":content})
    }

    rule test_calculate_address_distance {
        select when test calc_address_dist
        pre{
            address1 = event:attr("address1")
            address2 = event:attr("address2")
            content = map_quest:get_address_dist(address1, address2)
        }
        send_directive("say", {"distance":content})
    }

    // rule test_calculate_distance {
    //     select when test calc_dist
    //     pre{
    //         lat1 = event:attr("lat1")
    //         long1 = event:attr("long1")
    //         lat2 = event:attr("lat2")
    //         long2 = event:attr("long2")
    //         content = map_quest:calculate_distance(lat1, long1, lat2, long2)
    //     }
    //     send_directive("say", {"data":content})
    // }

    // rule test_calculate_address_distance {
    //     select when test calc_address_dist
    //     pre{
    //         address1 = event:attr("address1")
    //         address2 = event:attr("address2")
    //         content = map_quest:calculate_address_distance(address1, address2)
    //     }
    //     send_directive("say", {"data":content})
    // }
}
   