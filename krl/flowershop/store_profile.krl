ruleset store_profile {
    meta {
        shares profile_info
        provides store_name, store_address, notify_number, username, public_eci
    }
    global {
        default_address = "669+E+800+N%2C+Provo%2C+UT%2C+84606"
        default_name = "Store"
        default_notify_number = "12082513706"

        store_address = function() {
            return ent:address.defaultsTo(default_address)
        }
        store_name = function() {
            return ent:name.defaultsTo(default_name)
        }
        notify_number = function() {
            return ent:notify_number.defaultsTo(default_notify_number)
        }
        username = function(){
            return ent:username
        }
        public_eci = function(){
            return ent:public_eci
        }

        profile_info = function() {
            result = {"address": store_address(),
                     "name": store_name(),
                     "notify_number": notify_number(),
                     "username": ent:username,
                     "public_eci": ent:public_eci
            }
            return result
        }
    }
   
    rule update_profile {
        select when store update_profile
        pre{
            t_address = event:attr("address").defaultsTo(store_address())
            t_name = event:attr("name").defaultsTo(store_name())
            t_notify_number = event:attr("notify_number").defaultsTo(notify_number())

            t_username =  ent:username.defaultsTo(event:attr("username"))
            t_public_eci = ent:public_eci.defaultsTo(event:attr("public_eci"))
        }
        send_directive("say", {"data":{"address": t_address, 
                                        "name":t_name,
                                        "notify_number":t_notify_number,
                                        "username":t_username,
                                        "public_eci":t_public_eci}})
        always{
            ent:address := t_address
            ent:name := t_name
            ent:notify_number := t_notify_number
            ent:username := t_username
            ent:public_eci := t_public_eci
        }
    }
  
  }