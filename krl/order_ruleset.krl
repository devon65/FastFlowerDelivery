// click on a ruleset name to see its source here
ruleset flower_order{
    
    meta{


        name "Flower Order Ruleset"
        description <<L>>
        author "Levi Del Rio"
        
        
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscription  
        
        shares __testing, test, checkStatus
        
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
            {}.put("orderID", ent:orderID).put("itemID", ent:itemID).put("status", ent:status).put("driver", ent:driver)
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

   
    rule acceptOrder{
        select when order accept
        pre{
            driver = event:attr("driver").defaultsTo("unknown") // name 
            status = event:attr("status").defaultsTo("accepted")
        }
        if (driver == null) then
            send_directive("\"driver\" parameter not given")
        notfired{
            ent:status := "accepted";
            ent:driver := driver;
            raise update event "status" attributes{
                "status" : status,
                "driver" : driver
            }
        }
    }



    // Create Order Pico
    rule orderCreated{
        select when connect driver
        pre{
            driverEci = event:attr("driverEci")
            orderID = event:attr("orderID")
            itemID = event:attr("itemID")
        } 
        always{
            ent:status := ent:status.defaultsTo("open");
            ent:orderID := orderID;
            ent:driver := "";
            ent:itemID := itemID;
            raise wrangler event "sendSubscription" attributes{
                "driverEci" : driverEci
            }
            
        }
        
    }


  rule sendSubscriptions{
    select when wrangler sendSubscription
    pre{
      eci = event:attr("driverEci").klog("Subscribe to this Driver wellknown")
    }
    
    always{
      raise wrangler event "subscription" attributes{
        "name":"Order",
        "wellKnown_Tx": eci,
        "Tx_role": "Driver",
        "Rx_role": "Order"
      }
    }
  }
 
 
  
  
}