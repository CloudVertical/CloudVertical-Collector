module CvClient
  module Provider
    module Aws
      class BillingProgramatic < CvClient::Provider::Aws::Base
        
        TYPE = "billing"
        PATH = "/v01/programatic_statements.json"
        
        def fetch_data()
          return if (@bucket_name.nil? || @bucket_name.empty?)
          @data = []
          s3 = RightAws::S3Interface.new(@access_key_id, @secret_access_key)
          key = s3.list_bucket(@bucket_name).find{|e| e[:key] =~ /#{get_timestamp.strftime("%Y-%m")}.csv/}
          return if key.nil?
          key = key[:key]
          content = ''
          rhdr = s3.get(@bucket_name,key) do |chunk|
            content += chunk
          end          
          @data << common_data.merge({:data => content, :timestamp => get_timestamp})
          
          return true
        rescue RightAws::AwsError => e
          false
        end
        
        def common_data()
          return {
            :cloud_connection_id =>@cloud_connection_id,
            :tags => parse_tags([])
          }
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end