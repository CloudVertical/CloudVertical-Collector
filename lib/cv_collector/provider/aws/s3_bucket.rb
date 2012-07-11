module CvCollector
  module Provider
    module Aws
      class S3Bucket < CvCollector::Provider::Aws::Base
        
        RESOURCE_TYPE = 's3_bucket'
        PATH = "/v01/storage.json"

        def fetch_data(cc = [])
          data = {:provider => PROVIDER, :storage_type => RESOURCE_TYPE}
          date = Time.now.utc - 3600 * 24
          prefix = (get_timestamp - 24*3600).strftime("%Y-%m-%d")
          
          @s3 = RightAws::S3Interface.new(@access_key_id, @secret_access_key)
          buckets = @s3.list_all_my_buckets
          buckets.each do |bucket|
            location = @s3.bucket_location(bucket[:name])
            if location.empty?
              location = 'US' 
            elsif location == 'eu-west-1'
              location = 'EU'
            end
            data.merge!(:region => location, :capacity => 0)
            @data << parse_data(bucket).merge(data)
            
          end
          send 
          bucket_specs = get_specs
          usage_data = log_analyse2(bucket_specs)
          @data = usage_data
          return []
             
        end
        
        def log_analyse2(bucket_specs)
          prefix = (get_timestamp - 24*3600).strftime("%Y-%m-%d")
          result = []
          bucket_specs.each do |spec|
            get_requests = parse_child({'parent_id' => spec['name'], 'region' => spec["region"], 'reference_id' => "get_requests-#{prefix}", 'capacity' => 0, 'storage_type' => "get_requests"})
            other_requests = parse_child({'parent_id' => spec['name'], 'region' => spec["region"], 'reference_id' => "other_requests-#{prefix}", 'capacity' => 0, 'storage_type' => "other_requests"})
            data_transfer = parse_child({'parent_id' => spec['name'], 'region' => spec["region"], 'reference_id' => "data_transfer-#{prefix}", 'capacity' => 0, 'storage_type' => "data_transfer"})
            begin
              next if !spec.has_key?('targetbucket') || !spec.has_key?("targetprefix")
              @s3.incrementally_list_bucket(spec['targetbucket'], {'prefix' => spec["targetprefix"] + prefix}) do |res|
                res[:contents].each do |item|
                  p item[:key]
                  tmp_get_request, tmp_other_request, tmp_data_out = count_data(S3Parser.run(:file => @s3.get(spec['targetbucket'], item[:key])[:object]))
                  get_requests['capacity'] += tmp_get_request
                  other_requests['capacity'] += tmp_other_request
                  data_transfer['capacity'] += tmp_data_out
                end
              end
            rescue => e
              p e
              p e.backtrace
              p "\n\nNo bucket: #{spec['targetbucket']}\n"
              next
            end
            result << get_requests
            result << other_requests
            result << data_transfer
          end
          result
        end
          
        def log_analyse (bucket_specs)
          s3 = RightAws::S3.new(@access_key_id, @secret_access_key)
          result = []
          bucket_specs.each do |spec|
            data = {}
            tmp = []
            if spec["targetbucket"] 
              bucket = s3.bucket(spec["targetbucket"])
              next if bucket.nil?
              prefix = (get_timestamp - 24*3600).strftime("%Y-%m-%d")
              
              get_requests = parse_child({'parent_id' => spec['name'], 'region' => spec["region"], 'reference_id' => "get_requests-#{prefix}", 'capacity' => 0, 'storage_type' => "get_requests"})
              other_requests = parse_child({'parent_id' => spec['name'], 'region' => spec["region"], 'reference_id' => "other_requests-#{prefix}", 'capacity' => 0, 'storage_type' => "other_requests"})
              data_transfer = parse_child({'parent_id' => spec['name'], 'region' => spec["region"], 'reference_id' => "data_transfer-#{prefix}", 'capacity' => 0, 'storage_type' => "data_transfer"})
              
              bucket.keys('prefix' => spec["targetprefix"] + prefix).each do |key|
                tmp_get_request, tmp_other_request, tmp_data_out = count_data(S3Parser.run(:file => key.data))
                get_requests['capacity'] += tmp_get_request
                other_requests['capacity'] += tmp_other_request
                data_transfer['capacity'] += tmp_data_out
              end
              result << get_requests
              result << other_requests
              result << data_transfer
            end
          end
          return result
        end
        
        def parse_data(bucket)
          return {'cloud_connection_id' => @cloud_connection_id,
                  'reference_id' => bucket[:name],
                  'timestamp' => get_timestamp,
                  'status' => 'running',
                  'tags' => parse_tags([])}
    
        end
        
        def count_data(data)
          getr = data.find_all{|x| x[:request_uri].match(/^get/i) }
          get_request = getr.count
          data_out = getr.inject(0.0){|x,y| x + y[:bytes_sent].to_i}/1024.0/1024
          other_request = data.length - get_request
          return [get_request, other_request, data_out]
        end
        
        def parse_child(data)
          return {'provider' => PROVIDER,
                  'cloud_connection_id' => @cloud_connection_id,
                  'timestamp' => (get_timestamp - 24 * 3600).end_of_day,
                  'status' => 'running',
                  'tags' => parse_tags([])}.merge(data)
        end
        
        def calculate_size(s3, bucket)
          items = nil
          standard_size = 0
          rrs_size = 0
          s3.incrementally_list_bucket(bucket[:name]) do |result|
            items = result[:contents]
            standard_items = items.find_all{|item| item[:storage_class] == "STANDARD"}
            rss_items = items.find_all{|item| item[:storage_class] == "REDUCED_REDUNDANCY"}
            standard_size += standard_items.inject(0){|sum, item| sum + item[:size]}/1024.0/1024
            rrs_size += rss_items.inject(0){|sum, item| sum + item[:size]}/1024.0/1024
          end

          return {'standard_capacity' => standard_size, 'rrs_capacity' => rrs_size}
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
          @data = []
        end
        
        def get_specs
          body = connection.get("/v01/storage/bucket_specs?format=json&cloud_connection_id=#{@cloud_connection_id}", @auth_token).body
          JSON.parse(body)
        end

      end
    end
  end
end