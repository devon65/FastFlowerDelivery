ruleset driver_gossip {
    meta {
        use module io.picolabs.subscription alias subscriptions
        provides get_all_order_messages
    }

    global{
        HEARTBEAT_INTERVAL_DEFAULT = 5

        get_all_order_messages = function(){
            return ent:rumor_messages
        }

        needed_messages_by_eci = function(eci, sender_eci){
            filtered_rumor_messages = ent:my_seen_messages.isnull() => [] |
            ent:my_seen_messages.filter(function(message_num, pico_id) {
                message_num.as("Number") > ent:seen_messages{[eci, pico_id]}.defaultsTo("-1").as("Number")
            })
            rumor_messages = filtered_rumor_messages.map(function(message_num, pico_id) {
                needed_message_number = ent:seen_messages{[eci, pico_id]}
                needed_message_number.isnull() => 0 | needed_message_number.as("Number") + 1
            })
            seen_messages = ent:seen_messages{eci}.filter(function(message_num, pico_id) {
                message_num.as("Number") != ent:my_seen_messages{pico_id}.defaultsTo("-1").as("Number")
            })
            seen_messages = ent:should_notify_reemergence{eci}.as("Boolean") => [true] | seen_messages
            return {"sender_eci":sender_eci, "eci":eci, "rumor": rumor_messages.klog("Rumor Messages filtered and mapped"), "seen":seen_messages}
        }

        peers_needing_message = function(){
            peers_and_messages = subscriptions:established("Tx_role","gossip_friend").map(function(subscription) {
                needed_messages_by_eci(subscription.klog("subscription: "){"Tx"}, subscription{"Rx"})
            })
            peers_in_need = peers_and_messages.klog("All Peers: ").filter(function(peer) {
                peer{"rumor"}.length() > 0 => true |
                peer{"seen"}.length() > 0 => true |
                false
            })
            return peers_in_need.klog("All Peers in need: ")
        }

        get_peer = function(){
            peers = peers_needing_message()
            return peers[random:integer(peers.length() - 1)].klog("Chosen Peer: ")
        }

        create_rumor_message = function(peer){
            needed_rumors = peer{"rumor"}
            store_ids = needed_rumors.keys()
            chosen_id = store_ids[random:integer(store_ids.length() - 1)].klog("randomly chosen_id")
            message = ent:rumor_messages.klog("rumor messages: "){[chosen_id, needed_rumors{chosen_id}.klog("message number")]}
            return message.isnull() => null | {"sender_eci": peer{"sender_eci"}, "eci": peer{"eci"}, "rumor": message}
        }

        create_seen_message = function(peer) {
            return peer{"seen"}.length() > 0 => 
            {"sender_eci": peer{"sender_eci"}, "eci": peer{"eci"}, "seen": ent:my_seen_messages.defaultsTo({})} |
            null
        }

        prepare_message = function(peer){
            message = random:integer(1).klog("randomly choosing message: ") > 0 => 
                        create_rumor_message(peer).defaultsTo(create_seen_message(peer)) |
                        create_seen_message(peer).defaultsTo(create_rumor_message(peer))
            return message.klog("Chosen Message:")
        }

        find_current_msg_num = function(store_id, candidate_num){
            return ent:rumor_messages{[store_id, candidate_num]}.klog("Find Current Msg: ") => 
                    find_current_msg_num(store_id, candidate_num + 1) |
                    candidate_num - 1
        }

        calculate_current_msg_num = function(store_id, old_msg_num, new_msg_num){
            return new_msg_num == old_msg_num + 1 => 
                    find_current_msg_num(store_id, new_msg_num + 1).klog("Find Current Msg Result: ") |
                    old_msg_num
        }
    }

    rule set_notify_reemergence{
        select when gossip reemergence
        foreach subscriptions:established("Tx_role","gossip_friend") setting (subscription)
          always {
            ent:should_notify_reemergence{subscription{"Tx"}} := true
          }
    }

    rule start_heartbeat{
        select when gossip start_heartbeat where ent:is_gossip_paused.defaultsTo(true)
        always{
            raise gossip event "reemergence"
            ent:is_gossip_paused := false
            schedule gossip event "heartbeat" at time:add(time:now(), 
            {"seconds": ent:heartbeat_interval.defaultsTo(HEARTBEAT_INTERVAL_DEFAULT)})
        }
    }

    rule update_heartbeat{
        select when gossip update_heartbeat
        pre{
            heartbeat_interval = event:attr("heartbeat_interval").klog("New heartbeat: ")
        }
        if heartbeat_interval then noop()
        fired{
            ent:heartbeat_interval := heartbeat_interval
        }
    }

    rule pause_gossip{
        select when gossip pause_heartbeat
        always{
            ent:is_gossip_paused := true
        }
    }

    // Edit this rule to account for orders instead of temperature messages
    rule collect_internal_orders {
        select when order collect_internally 
        pre{
            message = event:attr("message")
            store_id = message{["store", "storeEci"]}

            new_msg_num = rumor{"orderID"}.split(re#:#)[1].as("Number")
            old_msg_num = ent:my_seen_messages{store_id}.as("Number").defaultsTo(0)
            current_msg = calculate_current_msg_num(store_id, 
                old_msg_num.klog("************************oldMessageNumber:"), 
                new_msg_num.klog("************************newMessageNumber:"))
        }
        always{
            ent:rumor_messages{[store_id, message_number]} := message.klog("New Order Message: ")
            ent:my_seen_messages{store_id} := message_number
        }
    }

    rule send_seen_message{
        select when gossip send_message
        pre{
            message_info = event:attr("message")
            eci = message_info{"eci"}
            sender_eci = message_info{"sender_eci"}
            message = message_info{"seen"}
        }
        if message then
            event:send({"eci": eci, 
                        "domain":"gossip", 
                        "type":"seen", 
                        "attrs":{"message": message,
                                "sender_eci": sender_eci}}.klog("Sending Seen Message: "))
        always{
            ent:should_notify_reemergence{eci} := false
        }
    }

    rule send_rumor_message{
        select when gossip send_message
        pre{
            message_info = event:attr("message")
            eci = message_info{"eci"}
            sender_eci = message_info{"sender_eci"}
            message = message_info{"rumor"}
            message_number = message{"orderID"}.split(re#:#)[1].as("Number")
            message_store_id = message{"StoreID"}
        }
        if message then
            event:send({"eci": eci, 
                        "domain":"gossip", 
                        "type":"rumor", 
                        "attrs":{"message": message, "sender_eci": sender_eci}}.klog("Sending Rumor Message: "))
        fired {
            ent:seen_messages{[eci, message_store_id]} := message_number
        }
    }

    rule handle_heartbeat{
        select when gossip heartbeat where ent:is_gossip_paused.defaultsTo(false) == false
        pre{
            peer = get_peer()
            message = prepare_message(peer)
        }
        always{
            raise gossip event "send_message" attributes {
                "message" : message
            } if (message.isnull() == false)
            schedule gossip event "heartbeat" at time:add(time:now(), 
            {"seconds": ent:heartbeat_interval.defaultsTo(HEARTBEAT_INTERVAL_DEFAULT)})
        }
    }

    rule handle_rumor_message{
        select when gossip rumor where ent:is_gossip_paused.defaultsTo(false) == false
        pre{
            rumor = event:attr("message").klog("Received Rumor Message: ")
            store_id = rumor{"StoreID"}
            sender = event:attr("sender_eci")

            new_msg_num = rumor{"orderID"}.split(re#:#)[1].as("Number")
            old_msg_num = ent:my_seen_messages{store_id}.as("Number").defaultsTo(0)
            current_msg = calculate_current_msg_num(store_id, 
                old_msg_num.klog("************************oldMessageNumber:"), 
                new_msg_num.klog("************************newMessageNumber:"))
        }
        if rumor then noop()
        fired{
            ent:rumor_messages{[store_id, new_msg_num]} := rumor
            ent:my_seen_messages{store_id} := current_msg.klog("**********************************message_number")
            ent:seen_messages{[sender, store_id]} := new_msg_num
        }
    }

    rule handle_seen_message{
        select when gossip seen where ent:is_gossip_paused.defaultsTo(false) == false
        pre{
            message = event:attr("message").klog("Received Seen Message: ")
            sender = event:attr("sender_eci")
        }
        if message then noop()
        fired{
            ent:seen_messages{sender} := message
        }
    }
}