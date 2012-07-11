module CvClient
  module Provider
    module Aws
      class Auth < CvClient::Provider::Base::Auth
        
        def ask_for_credentials
          puts "Enter your Amazon Web Services credentials."

          label = ask("Label: ")
          email = ask("Email:")
          password = silent_ask("Password:")
          access_key_id = ask("Access Key ID:")
          secret_access_key = ask("Secret Access Key:")
          cloud_connection_id = ask("Cloud Connection ID:")

          self.credentials = {
            :label => label.to_s,
            :email => email.to_s, 
            :password => password.to_s, 
            :access_key_id => access_key_id.to_s, 
            :secret_access_key => secret_access_key.to_s,
            :cloud_connection_id => cloud_connection_id.to_s
          }
        end
      end
    end
  end
end