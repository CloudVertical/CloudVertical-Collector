module CvCollector
  module Provider
    module Cv
      class Auth < CvCollector::Provider::Base::Auth

        def ask_for_credentials
          puts "Enter your Cloud Vertical credentials."

          api_key = ask("API key: ")

          self.credentials = {
            :api_key => api_key.to_s
          }
        end
        
      end
    end
  end
end