ruleset driver_base {
    meta {
        // use module twilio_v2 alias twilio
        //     with account_sid = keys:twilio{"account_sid"}
        //         auth_token =  keys:twilio{"auth_token"}
        
        // use module map_quest alias map_quest
        //     with consumer_key = keys:map_quest{"consumer_key"}
        
        use module driver_gossip
        use module driver_profile alias profile
        share available_orders
    }
    global {
        text_from = "16013854081"

        dummy_driver = {"name": "Devon Howard", "notify_number": "12345678901"}
        dummy_order1 = {"orderID": "123abc",
                        "itemID": "Roses", 
                        "status":"open",
                        "customerAddress": "121+N+State+St%2C+Orem%2C+UT+84057",
                        "flowerShopAddress": "669+E+800+N%2C+Provo%2C+UT%2C+84606",
                        "driver":dummy_driver}

        dummy_order2 = {"orderID": "123abc2", 
                        "itemID": "Roses", 
                        "status":"closed",
                        "customerAddress": "121+N+State+St%2C+Orem%2C+UT+84057",
                        "flowerShopAddress": "669+E+800+N%2C+Provo%2C+UT%2C+84606",
                        "driver":dummy_driver}

        filter_order = function(order){
            order_distance = map_quest:get_address_dist(profile:driver_address(), order{"address"})
            in_range = order_distance <= profile:distance_threshold()
            is_open = order{status} == "open"
            is_owned = order{["driver", "username"]} == profile:username()
            return is_owned || (in_range && is_open)
        }

        // filter_all_orders = function(messages_map){

        // }

        available_orders = function() {
            {"123abc": dummy_order1, "123abc2":dummy_order2}
        }
    }

    rule accept_order {
        select when driver order_accepted
        pre{
            orderId = event:attr("orderId")
            orderEci = available_orders(){orderId}{"orderEci"}
        }
        send_directive("order_accepted", {"accepted":true})
    }

    rule order_delivered {
        select when driver order_delivered
        pre{
            orderId = event:attr("orderId")
        }
        send_directive("order_updated", {"updated":true})
    }
   
    rule process_new_order {
        select when order created
        pre {
            order = event:attr("order").klog("Order: ")
        }
        
        fired {
            raise order event "collect_internally" attributes {
                "message": order
            }
            raise order event "yas" attributes{

            }
        }
    }

    rule filter_all_orders {
        select when driver filter_orders
        foreach {"a" : 1, "b" : 2, "c" : 3} setting (storeId, order)
            foreach orders setting (order_num, order)
                if filter_order(order) then noop()
                fired {

                }

    }

    rule add_order_to_list {
        select when driver add_order where filter_order(event:attr("order"))
        pre{
            order = event:attr("order")
            orderID = order("orderID")
        }
        always{
            raise driver event "notify" attributes {
                "order": order
            }
            ent:drivers_orders{orderID} := order
        }
    }

    rule notify_of_new_order {
        select when driver notify
        pre{
            name = profile:driver_name()
            notify_number = profile:notify_number()
            message = <<Hey there #{name}! There is a new order available for delivery.>>
        }
        twilio:send_sms(notify_number, text_from, message.klog("Text Message: "))
    }  
  
}