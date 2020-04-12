ruleset api_keys {
    meta {
        key twilio {
              "account_sid": "", 
              "auth_token" : ""
        }
        provides keys twilio to twilio_v2, test_apis
        
        key map_quest {
              "consumer_key": ""
        }
        provides keys map_quest to map_quest, test_apis
    }
  }
  