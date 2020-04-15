// click on a ruleset name to see its source here
ruleset flower_order{
    
    meta{


        name "Flower Order Ruleset"
        description <<L>>
        author "Levi Del Rio"
        
        
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscription  
        
        shares __testing, test, checkStatus, orderInfo
        
    }
  
    global{

        __testing = {"queries" : [{"name" : "__testing"},
                                    {"name": "test"},
                                    {"name": "checkStatus"},
                                    {"name" : "orderInfo"}
                                    ],
                    "events" :[
                        {"domain" : "wrangler", "type" : "sendSubscription", "attrs" : ["driverEci"]},
                        {"domain" : "update", "type" : "status", "attrs" : ["status"]},
                        {"domain" : "order", "type" : "accept", "attrs" : ["driver", "status"]}

                    ]}

        test = function(){
            x = 1;
            x
        }

        checkStatus = function(){
            ent:status
        }

        orderInfo = function(){
            {}.put("orderID", ent:orderID)
            .put("itemID", ent:itemID)
            .put("status", ent:status)
            .put("driver", ent:driver)
            .put("buyer", ent:buyer)
            .put("orderEci", ent:orderEci)
            .put("address", ent:address)
            .put("store", ent:store)
        }

    }


    rule updateStatus{
        select when order update_status
        pre{
            order_status = event:attr("status")
        } 
        if order_status then noop()
        fired{
            ent:status := order_status
            raise order event "notify_store"
        } 
    }

    rule notifyStoreOfUpdate{
        select when order notify_store
        event:send({"eci" : wrangler:parent_eci(), 
                    "eid" : "changeStatus", 
                    "domain": "store",
                    "type" : "order_update",
                    "attrs" :{
                        "orderID": ent:orderID,
                        "status": ent:status,
                        "driver": ent:driver
                    }
        })
    }

    rule acceptOrder{
        select when order accept_driver where ent:status == "open"
        pre{
            driver = event:attr("driver").klog("Accept order selected") 
            driver_eci = driver{"driverEci"}
            status = "enroute"
            updated_order = orderInfo().put("driver", driver).put("status", status)
        }
        if driver_eci then 
            send_directive("order_accepted", {"accepted":true, "updated_order":updated_order})

        fired {
            ent:driver := driver
            ent:status := status
            raise wrangler event "subscription" attributes{
                "name":"Delivery",
                "wellKnown_Tx": driver_eci,
                "Tx_role": "Driver",
                "Rx_role": "Order"
            }
            raise order event "notify_store"
        }
    }

    rule rejectOrder{
        select when order accept_driver where not (ent:status == "open")
        send_directive("order_accepted", {"accepted":false, "updated_order":orderInfo()}.klog("Reject order selected"))
    }

    //This rule only runs when the subscription from a driver has been added. IF the status of order is not open, no other driver can subscribe to it.
    // rule acceptOrder{
    //     select when wrangler subscription_added where event:attr("bus"){"Tx_role"} == "Driver" && ent:status == "open"
    //     pre{
    //         driver = event:attr("driver").defaultsTo("unknown") // driver info 
    //         status = event:attr("status").defaultsTo("enroute")
    //         subInfo = event:attr("bus").klog("Bus")
    //     }
    //     always{
    //         ent:driver := driver
    //         ent:status := status
    //     }
    // }


    // Create Order Pico
    rule orderCreated{
        select when order initialize
        pre{
            order = event:attr("order")
        } 
        always{
            ent:orderID := order{"orderID"}
            ent:itemID := order{"itemID"}
            ent:status := order{"status"}
            ent:driver := order{"driver"}
            ent:buyer := order{"buyer"}
            ent:orderEci := order{"orderEci"}
            ent:address := order{"address"}
            ent:store := order{"store"}
        }
    }


    //Accept one driver subscription    
    // rule autoAccetSubscriptions{
    //     select when wrangler inbound_pending_subscription_added where event:attr("bus"){"Tx_role"} == "Driver" && ent:status == "open"
    //     pre{
    //         driver = event:attr("driver") 
    //         status = "enroute"
    //         updated_order = orderInfo().put("driver", driver).put("status", status)
    //     }
    //     if driver then 
    //         send_directive("order_accepted", {"accepted":true, "updated_order":updated_order})
    //     fired{
    //         ent:driver := driver
    //         ent:status := status
    //         raise wrangler event "pending_subscription_approval" attributes event:attrs
    //     }
    // }

    //Accept one driver subscription    
    // rule reject_other_driver_subscriptions{
    //     select when wrangler inbound_pending_subscription_added where event:attr("bus"){"Tx_role"} == "Driver" && not (ent:status == "open")
    //     send_directive("order_accepted", {"accepted":false})
    // }
}
