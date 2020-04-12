ruleset App {

    meta {

    }

     global {

     }

    rule create_order {
        select when app create_order
        pre{
            test = event:attr("location").klog("AAAAAAA: ")
        }
        send_directive("testing")
    }
}