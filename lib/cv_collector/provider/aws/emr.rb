module CvCollector
  module Provider
    module Aws
      class Emr < CvCollector::Provider::Aws::Base
        
        RESOURCE_TYPE = 'emr'
        STATUSES = { 'RUNNING' => 'running', 'WAITING' => 'waiting', 'SHUTTING_DOWN' => 'shutting_down', 'STARTING' => 'starting', 'COMPLETED' => 'completed', 'FAILED' => 'failed', 'TERMINATED' => 'terminated' }
        PATH = "/v01/computes.json"

        def fetch_data()
          REGIONS.each do |region|
            self.perform_action do
              emr = RightAws::EmrInterface.new(@access_key_id, @secret_access_key, :region => region)
              jobs = emr.describe_job_flows
              jobs.each do |job|
                @data << parse_data(job).merge({'region' => region})
              end
              jobs
            end
          end
          return true
        end
        
        def parse_data(job)
          resources = {'cpu' => 0, 'ram' => 0}
          return {'provider' => PROVIDER,
                  'compute_type' => RESOURCE_TYPE,
                  'cloud_connection_id' => @cloud_connection_id,
                  'reference_id' => job[:job_flow_id],
                  'label' => job[:name],
                  'platform' => 'linux',
                  'status' => STATUSES[job[:state]],
                  'launch_time' => job[:creation_date_time],
                  'tags' => parse_tags([])}.merge(resources)
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end
