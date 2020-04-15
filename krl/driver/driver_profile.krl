ruleset driver_profile {
    meta {
        use module io.picolabs.subscription alias subscription

        shares profile_info
        provides driver_name, driver_address, distance_threshold, notify_number, username, driverEci, profile_info
    }
    global {
        default_address = "669+E+800+N%2C+Provo%2C+UT%2C+84606"
        default_name = "Driver"
        default_dist_thresh = 40 //in miles
        default_notify_number = "12082513706"

        driver_address = function() {
            return ent:address.defaultsTo(default_address)
        }
        driver_name = function() {
            return ent:name.defaultsTo(default_name)
        }
        distance_threshold = function(){
            return ent:distance_thresh.defaultsTo(default_dist_thresh)
        }
        notify_number = function() {
            return ent:notify_number.defaultsTo(default_notify_number)
        }
        username = function(){
            return ent:username
        }
        driverEci = function(){
            return subscription:wellKnown_Rx(){"id"}.klog("Driver wellknown ECI ")
        }

        profile_info = function() {
            result = {"address": driver_address(),
                     "name": driver_name(),
                     "distance_threshold": distance_threshold(),
                     "notify_number": notify_number(),
                     "username": username(),
                     "driverEci": driverEci()
            }
            return result
        }
    }
   
    rule update_profile {
        select when driver update_profile
        pre{
            t_address = event:attr("address").defaultsTo(driver_address())
            t_name = event:attr("name").defaultsTo(driver_name())
            t_distance_thresh = event:attr("distance_threshold").defaultsTo(distance_threshold()).as("Number")
            t_notify_number = event:attr("notify_number").defaultsTo(notify_number())

            t_username =  ent:username.defaultsTo(event:attr("username"))
        }
        send_directive("say", {"data":{"address": t_address, 
                                        "name":t_name,
                                        "distance_threshold":t_distance_thresh, 
                                        "notify_number":t_notify_number,
                                        "username":t_username}})
        always{
            ent:address := t_address
            ent:name := t_name
            ent:distance_thresh := t_distance_thresh
            ent:notify_number := t_notify_number
            ent:username := t_username
            schedule driver event "clear_and_filter_orders" at time:add(time:now(), {"seconds":0})
        }
    }
  
  }