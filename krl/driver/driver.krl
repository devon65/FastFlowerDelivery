// click on a ruleset name to see its source here
ruleset driver{
    
    meta{


        name "Driver Ruleset"
        description <<L>>
        author "Levi Del Rio"
        
        
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscription  
        
        shares __testing, test
        
    }
  
    global{

        __testing = {"queries" : [{"name" : "__testing"},
                                    {"name": "test"}
                                    ],
                    "events" :[{"domain" : "wrangler", "type" : "sendSubscription", "attrs" : ["eci"]},
                                {"domain" : "driver", "type" : "name", "attrs" : ["name"]}]
                    }

        test = function(){
            x = 1;
            x
        }
    }
  
    //accepts any subscription < if the store sends a subscription to the driver >
    rule autoAccetSubscriptions{
        select when wrangler inbound_pending_subscription_added
        pre{
        }
        fired{
            raise wrangler event "pending_subscription_approval" attributes event:attrs
        }
    }
  
    //to received notifications from the store
    rule notificationReceived{
      select when order created
      pre{
        orderID = event:attr("orderID").klog("OrderID received")
        orderECI = event:attr("orderECI").klog("OrderECI received")
        itemID = event:attr("itemID").klog("ItemID received")
        buyer = event:attr("buyer").klog("buyer is : ")
      }    
      
    }
    
    //sets the name of the driver
    rule setDriverName{
      select when driver name
      pre{
        name = event:attr("name")
      }
      always{
        ent:driverName := name
      }
    }
    
    
    //to send a subscription to the order, make sure the Tx_role == "Order" and Rx_role == "Driver" 
    rule sendSubscriptions{
      select when wrangler sendSubscription
      pre{
        eci = event:attr("eci").klog("Subscribe to this order wellknown")
      }
      
      always{
        raise wrangler event "subscription" attributes{
          "name":"Order",
          "wellKnown_Tx": eci,
          "Tx_role": "Order",
          "Rx_role": "Driver",
          "driverName": ent:driverName
        }
      }
    }
  
  
  
  
}