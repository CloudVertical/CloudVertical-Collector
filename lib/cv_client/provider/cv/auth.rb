module CvClient
  module Provider
    module Cv
      class Auth < CvClient::Provider::Base::Auth

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