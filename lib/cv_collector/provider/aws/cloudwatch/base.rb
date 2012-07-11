module CvCollector
  module Provider
    module Aws
      module CloudWatch
        class Base < CvCollector::Provider::Aws::Base
      
          PATH = "/v01/computes/0/usages.json"
          PERIOD = 600
          SOURCE = 'CloudWatch'

          # def parse_data(metric, instance_id, tags, measure_name)
          # return metric.merge({:tags => parse_tags(tags), 
          def parse_data(metric, instance_id, resource_type, measure_name)
            return metric.merge({:cloud_connection_id =>@cloud_connection_id,
                               :tags => [],             
                               :usage_type => measure_name, 
                               :source => SOURCE, 
                               :period => PERIOD, 
                               :reference_id => instance_id,
                               :resource_type => resource_type,
                               :sample => metric.delete(:samples),
                               :total => 100})
          end

          def fetch_data
            set_time_range()
          end

          def new?
            @connection ||= CvCollector::Core::Connection.new
            res_type = self.class::RESOURCE_TYPE
            body = @connection.get("/v01/usages/is_new?limit=1&resource_type=#{res_type}&format=json", @auth_token).body
            p res_type
            p body
            if @auth_token =="Mvsv5Fe1xcB73shzFpy6"
              return false
            end
              JSON.parse(body).size == 0 
          end
          
          def set_time_range
            @now = Time.now.utc            
            @start_time, @end_time = if new?
              [Time.now.change({:day => 1}).iso8601, @now.iso8601]
            else
              [(@now - 3600).iso8601, @now.iso8601]
            end            
          end

          def send
            connection.post({:data => @data, :auth_token => @auth_token}, PATH)
          rescue => e
            raise e
          end
          
        end 
      end
    end
  end
end