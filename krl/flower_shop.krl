// click on a ruleset name to see its source here
ruleset flower_shop{
    
    meta{


        name "Flower Shop Ruleset"
        description <<L>>
        author "Levi Del Rio"
        
        
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscription  
        
        shares __testing, test, orders, ordersByOrderID
        
    }
  
    global{

        __testing = {"queries" : [{"name" : "__testing"},
                                    {"name": "test"},
                                    {"name": "orders", "args":["orderID"]},
                                    {"name": "ordersByOrderID", "args" : ["orderID"]}
                                  ],
                    "events" :[
                        {"domain" : "create", "type" : "order", "attrs" : ["itemID", "address", "user"]},
                        {"domain" : "status", "type":"changed", "attrs" : ["orderID", "status"]},
                        {"domain" : "reset", "type" : "info"}]
                    }

        test = function(){
            wellknownRX = subscription:wellKnown_Rx();
            wellknownRX 
        }

        orders = function(orderID){
            (orderID.isnull() || (orderID == "")) => ent:orderStatus | ordersByOrderID(orderID)
        }

        ordersByOrderID = function(orderID){
            result = ent:orderStatus.filter(function(a){
                a{"orderID"} == orderID
            });
            result
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
            user = event:attr("user")
            address = event:attr("address")

            orderID = random:uuid()

            myWellKnownRX = subscription:wellKnown_Rx(){"id"}.klog("Store wellknown ECI "); 

            rand =  random:integer(subscription:established("Tx_role", "Driver").length()-1).klog("initial random number")
            randomDriver = subscription:established("Tx_role", "Driver")[rand]{"Tx"}.klog("Initial driverECI")
        }
        send_directive("CreatingOrderPico", {"For": itemID, "OrderID" : orderID})
        always{
            ent:orderIDs := ent:orderIDs.defaultsTo(0);
            ent:orderIDs := ent:orderIDs + 1;
            raise wrangler event "child_creation"
                attributes{ "itemID" : itemID,
                            "name" : "Order No. " + ent:orderIDs,
                            "color": "#a3921c", 
                            "address" : address,
                            "user": user,
                            "orderID" : orderID,
                            "driverEci" : randomDriver,
                            "storeEci" : myWellKnownRX,
                            "rids" : ["flower_order"],
                        }
        } 


    }

    //Stores the new order and connects the orderPico to the Driver
    rule store_new_order{
        select when wrangler child_initialized
        pre{
            orderID = event:attr("orderID")
            orderEci = event:attr("eci").klog("Order Eci from OrderPico")
            itemID = event:attr("itemID")
            driverEci = event:attr("driverEci").klog("Driver Eci from OrderPico")
            orderName = event:attr("name")
            order = {}.put("orderID", orderID).put("itemID", itemID).put("status", "open").put("driver", "")
        }
        //create a subscription with the driver
        event:send(
            {"eci": orderEci, 
            "eid" : "createSubtoDriver",
            "domain" : "connect",
            "type" : "driver",
            "attrs" : {
                "driverEci" : driverEci,
                "orderID" : orderID,
                "itemID" : itemID
            }
        })
        always{
            ent:orderStatus := ent:orderStatus.defaultsTo([]);
            ent:orderStatus := ent:orderStatus.append(order)
        }
    }

    rule orderStatusChanged{
        select when status changed
        pre{
            orderID = event:attr("orderID")
            itemID = event:attr("itemID")
            orderStatus = event:attr("status")
            driver = event:attr("driver")
            order = {}.put("orderID", orderID).put("itemID", itemID).put("status", orderStatus).put("driver", driver)
        }
        always{
            ent:orderStatus := ent:orderStatus.filter(function(a){
                a{"orderID"}.klog("oderIDinArray") != orderID.klog("orderID given")
            }).klog("After");
            ent:orderStatus := ent:orderStatus.append(order);
        }
    }
 
    rule resetAll{
        select when reset info
        always{
            ent:orderStatus := [];
            ent:orderIDs := 0;

    }
  }
}  