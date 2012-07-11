require 'fileutils'
module CvClient
  module Provider
    module Base
      class Auth
        attr_accessor :credentials
    
        def echo_off
          system "stty -echo"
        end

        def echo_on
          system "stty echo"
        end
        
        def ask_for_and_save_credentials
          @credentials = ask_for_credentials
          write_credentials
        end

        def ask_for_password_on_windows
          require "Win32API"
          char = nil
          password = ''

          while char = Win32API.new("crtdll", "_getch", [ ], "L").Call do
            break if char == 10 || char == 13 # received carriage return or newline
            if char == 127 || char == 8 # backspace and delete
              password.slice!(-1, 1)
            else
              # windows might throw a -1 at us so make sure to handle RangeError
              (password << char.chr) rescue RangeError
            end
          end
          puts
          return password
        end

        def silent_ask(msg)
          echo_off
          password = ask(msg)
          echo_on
          return password
        end

        def write_credentials()
          FileUtils.mkdir_p(File.dirname(credentials_file))
          
          File.open( credentials_file, 'w' ) do |out|
            YAML.dump( self.credentials, out )
          end
          set_credentials_permissions
          print "Config file written at #{credentials_file}\n"
        end
        
        def credentials_file
          extracted_subfolder_name = self.class.name.split("::")[-2].downcase
          "#{self.class.home_directory}/.cvc/#{extracted_subfolder_name}/credentials"
        end      
        
        def self.auth_key_file_exists?(type)
          File.exists?("#{home_directory}/.cvc/#{type}/credentials")
        end

        def set_credentials_permissions
          FileUtils.chmod 0700, File.dirname(credentials_file)
          FileUtils.chmod 0600, credentials_file
        end

        def delete_credentials
          FileUtils.rm_f(credentials_file)
          clear
        end
        
        def self.home_directory
          ENV['HOME']
        end
      end
    end
  end
end