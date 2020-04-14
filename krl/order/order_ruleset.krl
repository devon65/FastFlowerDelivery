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
            {}.put("orderID", ent:orderID).put("itemID", ent:itemID).put("status", ent:status).put("driver", ent:driver).put("buyer", ent:buyer)
        }

    }


    rule updateStatus{
        select when update status
        pre{
            order_status = event:attr("status").defaultsTo("open")
            driver = event:attr("driver").defaultsTo("")
        } 
        event:send({"eci" : wrangler:parent_eci(), 
                    "eid" : "changeStatus", 
                    "domain": "status",
                    "type" : "changed",
                    "attrs" :{
                        "orderID": ent:orderID,
                        "status": order_status,
                        "driver": ent:driver,
                        "itemID" : ent:itemID
                    }})
        always{
            ent:status := order_status
        } 
    }

    //This rule only runs when the subscription from a driver has been added. IF the status of order is not open, no other driver can subscribe to it.
    rule acceptOrder{
        select when wrangler subscription_added where event:attr("bus"){"Tx_role"} == "Driver" && ent:status == "open"
        pre{
            driver = event:attr("driver").defaultsTo("unknown") // name 
            status = event:attr("status").defaultsTo("accepted")
            subInfo = event:attr("bus").klog("Bus")
        }
        always{
            ent:status := "accepted"
        }
    }


    // Create Order Pico
    rule orderCreated{
        select when initialize data
        pre{
            driverEci = null
            orderID = event:attr("orderID")
            itemID = event:attr("itemID")
            buyer = event:attr("buyer")
        } 
        always{
            ent:status := ent:status.defaultsTo("open");
            ent:orderID := orderID;
            ent:driver := "";
            ent:itemID := itemID;
            ent:buyer := buyer
            
        }
    }


    //Accept subscriptions    
    rule autoAccetSubscriptions{
        select when wrangler inbound_pending_subscription_added where ent:status == "open"
        pre{
            driver = event:attr("driverName")
        }
        always{
            ent:driver := driver;
            raise wrangler event "pending_subscription_approval" attributes event:attrs
        }
    }
 
  
}
