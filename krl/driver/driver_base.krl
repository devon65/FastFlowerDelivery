ruleset driver_base {
    meta {
        use module twilio_v2 alias twilio
            with account_sid = keys:twilio{"account_sid"}
                auth_token =  keys:twilio{"auth_token"}
        
        use module map_quest alias map_quest
            with consumer_key = keys:map_quest{"consumer_key"}
        
        use module driver_gossip
        use module driver_profile alias profile
    }
    global {
        text_from = "16013854081"
    }
   
    rule process_new_order {
        select when order available
        pre {
            order_attrs = event:attrs.klog("Order Attrs: ")
        }
        
        fired {
            raise order event "collect_internally" attributes {
                "message": message
            }
            raise order event "yas" attributes{

            }
        }
    }

    rule add_order_to_list {
        select when order add_to_list 

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