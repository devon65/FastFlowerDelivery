ruleset driver_base {
    meta {
        use module api_keys
        use module twilio_v2 alias twilio
            with account_sid = keys:twilio_account_sid
                auth_token = keys:twilio_auth_token
        
        use module map_quest alias map_quest
            with consumer_key = keys:map_quest
        
        use module driver_gossip alias gossip
        use module driver_profile alias profile
        share orders
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
            order_distance = map_quest:get_address_dist(profile:driver_address(), order.klog("order to filter: "){"address"})
            in_range = (order_distance.klog("Distance in miles:") <= profile:distance_threshold().klog("Driver distance threshold:"))
            is_open = order{"status"} == "open"
            is_owned = order{["driver", "username"]} == profile:username()
            return is_owned.klog("is_owned: ") || (in_range.klog("in_range: ") && is_open.klog("is_open: "))
        }

        orders = function(orderID) {
            (orderID.isnull() || (orderID == "")) => ent:driver_orders.values().defaultsTo([]) | ent:driver_orders{orderID}.defaultsTo([])
        }

        accept_order = function(order_eci) {
            accept_order_url = <<http://localhost:8080/sky/event/#{order_eci}/flower/order/accept_driver>>
            result = http:get(accept_order_url, qs = {
                "driver": profile:profile_info()
            }){"content"}.decode().klog("Get Request result: ")
            is_accepted = result{"directives"}[0]{"options"}
            return is_accepted.klog("accept_order function result: ")
        }
    }

    rule accept_order {
        select when driver order_accepted
        pre{
            orderID = event:attr("orderID")
            order = orders(orderID)
            order_eci = order{"orderEci"}
            order_accepted = order_eci => accept_order(order_eci) | {"accepted":false}
            is_accepted = order_accepted{"accepted"}.klog("Accept Order Successful: ")
            updated_order = order_accepted{"updated_order"}
        }
        send_directive("is_order_accepted", order_accepted)
        always{
            ent:driver_orders{orderID} := updated_order if updated_order
            raise gossip event "update_message" attributes{
                "message": ent:driver_orders{orderID}
            } if updated_order
        }
    }

    rule order_delivered {
        select when driver order_delivered
        pre{
            orderID = event:attr("orderID")
        }
        send_directive("order_updated", {"updated":true})
    }
   
    rule process_new_order {
        select when order created
        pre {
            order = event:attr("order").klog("Order: ")
        }
        
        fired {
            raise gossip event "collect_internally" attributes {
                "message": order
            }
            raise driver event "add_order" attributes{
                "order": order
            }
        }
    }

    rule clear_and_filter_all_orders {
        select when driver clear_and_filter_orders
        always{
            ent:driver_orders := {}
            raise driver event "add_filtered_orders"
        }
    }

    rule filter_all_orders_then_add {
        select when driver add_filtered_orders
        foreach gossip:get_all_order_messages() setting (orders, storeId)
            foreach orders.klog("All Order Messages") setting (order, order_num)
                if filter_order(order) then noop()
                fired {
                    ent:driver_orders{order{"orderID"}} := order
                }
    }

    rule add_order_to_list {
        select when driver add_order where filter_order(event:attr("order"))
        pre{
            order = event:attr("order")
            orderID = order{"orderID"}
        }
        always{
            raise driver event "notify" attributes {
                "order": order
            }
            ent:driver_orders{orderID} := order
        }
    }

    rule notify_of_new_order {
        select when driver notify
        pre{
            name = profile:driver_name()
            notify_number = profile:notify_number()
            message = <<Hey there #{name}! There's a new flower order available for delivery.>>
        }
        twilio:send_sms(notify_number, text_from, message.klog("Text Message: "))
    }  

    rule autoAcceptSubscriptions{
        select when wrangler inbound_pending_subscription_added
        pre{
        }
        fired{
            raise wrangler event "pending_subscription_approval" attributes event:attrs
        }
    }
  
}