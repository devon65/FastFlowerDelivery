// click on a ruleset name to see its source here
ruleset flower_shop{
    
    meta{


        name "Flower Shop Ruleset"
        description <<L>>
        author "Levi Del Rio"
        
        
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscription  
        use module store_profile alias profile
        
        shares __testing, test, orders, ordersByOrderID
        
    }
  
    global{

        __testing = {"queries" : [{"name" : "__testing"},
                                    {"name": "test"},
                                    {"name": "orders", "args":["orderID"]},
                                    {"name": "ordersByOrderID", "args" : ["orderID"]}
                                  ],
                    "events" :[
                        {"domain" : "create", "type" : "order", "attrs" : ["itemID", "address", "buyer"]},
                        {"domain" : "status", "type":"changed", "attrs" : ["orderID", "status"]},
                        {"domain" : "reset", "type" : "info"}]
                    }

        test = function(){
            wellknownRX = subscription:wellKnown_Rx();
            wellknownRX 
        }

        orders = function(orderID){
            (orderID.isnull() || (orderID == "")) => ent:orderStatus.values() | ordersByOrderID(orderID)
        }

        ordersByOrderID = function(orderID){
            ent:orderStatus{orderID}
        }

    }
   

    //accepts any subscription
    rule autoAccetSubscriptions{
        select when wrangler inbound_pending_subscription_added
        always{
            raise wrangler event "pending_subscription_approval" attributes event:attrs
        }
    }
 


    // Create An Order 
    rule create_order{
        select when create order 
        pre{
            itemID = event:attr("itemID")
            buyer = event:attr("buyer")
            address = event:attr("address")
            orderID = random:uuid() + ":" + ent:orderIDs.defaultsTo(0)
            store = profile:profile_info()
            name = "Order No. " + ent:orderIDs.defaultsTo(0)
            order = {   "itemID" : itemID,
                        "address" : address,
                        "buyer": buyer,
                        "orderID" : orderID,
                        "driver" : null,
                        "status" : "open",
                        "store" : store
                    }
            // myWellKnownRX = subscription:wellKnown_Rx(){"id"}.klog("Store wellknown ECI "); 
            // rand =  random:integer(subscription:established("Tx_role", "Driver").length()-1).klog("initial random number")
            // randomDriver = subscription:established("Tx_role", "Driver")[rand]{"Tx"}.klog("Initial driverECI")
        }
        send_directive("CreatingOrderPico", {"For": itemID, "OrderID" : orderID})
        always{
            raise wrangler event "child_creation"
                attributes{ "name" : name,
                            "color": "#a3921c", 
                            "order": order,
                            "rids" : ["flower_order"],
                        }
            ent:orderIDs := ent:orderIDs.defaultsTo(0) + 1;
        } 
    }

    //Stores the new order and connects the orderPico to the Driver
    rule store_new_order{
        select when wrangler child_initialized
        pre{
            order = event:attr("order")
            orderID = order{"orderID"}
            orderEci = event:attr("eci").klog("Order Eci from OrderPico")
            orderName = event:attr("name")
            editedOrder = order.put("orderEci", orderEci)
        }
        event:send(
            {"eci": orderEci, 
            "eid" : "createSubtoDriver",
            "domain" : "order",
            "type" : "initialize",
            "attrs" : {
                "order": editedOrder
            }
        })
        always{
            ent:orderStatus{orderID} := order
            raise store event "notify_drivers" attributes{
                "order" : editedOrder
            }
        }
    }

    rule notifyEveryone{
        select when store notify_drivers
        foreach subscription:established() setting(sub)
        pre{
            order = event:attr("order")
        }
        if (sub{"Tx_role"} == "Driver") then
            event:send({
                "eci": sub{"Tx"},
                "eid" : "newOrderNotification",
                "domain": "order",
                "type" : "created",
                "attrs":{
                    "order": order
                }
            })
        
    }



    rule orderStatusChanged{
        select when store order_update
        pre{
            orderID = event:attr("orderID")
            orderStatus = event:attr("status")
            driver = event:attr("driver")
        }
        always{
            ent:orderStatus{[orderID, "status"]} := orderStatus
            ent:orderStatus{[orderID, "driver"]} := driver
        }
    }
 
    rule resetAll{
        select when reset info
        always{
            ent:orderStatus := {};
            ent:orderID := 0;
    }
  }
}
