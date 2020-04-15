ruleset App {
    meta {
        use module io.picolabs.wrangler alias wrangler
    }
    global {

    }
   
    //Store Pico Creation
    rule store_already_exists {
        select when store new_store
        pre {
            store_name = event:attr("name")
            username = event:attr("username")
            exists = ent:stores >< username
        }
        if exists then
            send_directive("store_ready", {"store_name": store_name})
    }

    rule store_needed {
        select when store new_store
        pre {
            store_name = event:attr("name")
            username = event:attr("username")
            store_address = event:attr("address")
            phone_number = event:attr("number")
            exists = ent:stores >< username
        }
        if not exists 
        then
            noop()
        fired {
            ent:stores{username} := {"name":store_name, "address":store_address, "number":phone_number}
            raise wrangler event "child_creation"
                attributes {"name": username,
                            "address": store_address,
                            "store_name": store_name,
                            "is_store": true,
                            "number":phone_number,
                            "color": "#ffff00",
                            "rids": ["store_profile", "flower_shop"]  }
        }
    }

    rule on_store_created {
        select when wrangler child_initialized where event:attr("is_store")
        pre {
            eci = event:attr("eci")
            id = event:attr("id")
            store_name = event:attr("store_name")
            username = event:attr("name")
            store_address = event:attr("address")
            phone_number = event:attr("number")
            exists = ent:stores >< username
        }
        if exists then
            event:send({"eci": eci, 
                        "domain":"store", 
                        "type":"update_profile", 
                        "attrs":{"name": store_name,
                                "username": username,
                                "address": store_address,
                                "number":phone_number}})

        fired{
            ent:stores{[name, "eci"]} := eci
            ent:stores{[name, "id"]} := id
        }
    }

    //Driver Pico Creation
    rule driver_already_exists {
        select when driver new_driver
        pre {
            driver_name = event:attr("name")
            username = event:attr("username")
            exists = ent:drivers >< username
        }
        if exists then
            send_directive("driver_ready", {"driver_name": driver_name})
    }

    rule driver_needed {
        select when driver new_driver
        pre {
            driver_name = event:attr("name")
            username = event:attr("username")
            phone_number = event:attr("number")
            driver_address = event:attr("address")
            distance_threshold = event:attr("distance_threshold")
            exists = ent:drivers >< driver_name
        }
        if not exists 
        then
            noop()
        fired {
            ent:drivers{username} := {"name":driver_name, 
                                    "address":driver_address, 
                                    "distance_threshold":distance_threshold, 
                                    "number":phone_number}
            raise wrangler event "child_creation"
                attributes {"name":username, 
                            "driver_name": driver_name,
                            "address":driver_address, 
                            "is_driver": true,
                            "distance_threshold":distance_threshold, 
                            "number":phone_number,
                            "color": "#31b0c4",
                            "rids": ["driver_profile", "driver_base", "driver_gossip"]  }
        }
    }

    rule on_driver_created {
        select when wrangler child_initialized where event:attr("is_driver")
        pre {
            eci = event:attr("eci")
            id = event:attr("id")
            driver_name = event:attr("driver_name")
            username = event:attr("name")
            phone_number = event:attr("number")
            driver_address = event:attr("address")
            distance_threshold = event:attr("distance_threshold")
            exists = ent:drivers >< username
        }
        if exists then
            event:send({"eci": eci, 
                        "domain":"driver", 
                        "type":"update_profile", 
                        "attrs":{"name": driver_name,
                                "username": username,
                                "address":driver_address, 
                                "distance_threshold":distance_threshold, 
                                "number":phone_number}})

        fired{
            ent:drivers{[name, "eci"]} := eci
            ent:drivers{[name, "id"]} := id
        }
    }
}