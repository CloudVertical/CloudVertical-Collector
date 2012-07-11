module CvCollector
  module Core
    class Connection
      # API_URL = 'http://localhost:3000/'
      DIVISOR = 500
      
      def initialize(url = API_URL)
        @faraday = Faraday.new(:url => url) do |builder|
          # builder.use Faraday::Request::UrlEncoded  
          # # builder.use Faraday::Request::JSON        
          builder.use Faraday::Response::Logger     
          # builder.use Faraday::Adapter::NetHttp     
          builder.request :json
          # builder.response :json, :content_type => /\bjson$/
          builder.use :instrumentation
          builder.adapter Faraday.default_adapter
          # builder.response :json
        end
      end
      
      def post(data, path = '/api/v1/push')
        return false if data[:data].empty?
        chunks = split_data(data[:data])
        chunks.each do |chunk|
          @faraday.post do |req|
            req.url path, :auth_token => data[:auth_token]||CV_API_KEY
            req.headers['Content-Type'] = 'application/json'
            req.body = {:data => chunk}
          end
        end
      rescue Faraday::Error::ConnectionFailed => e
        p "cv_collector ERROR: #{e}" 
      end
      
      def split_data(data)
        len = data.size;
        pieces = (data.size / DIVISOR) + 1
        mid = (len/pieces)
        chunks = []
        start = 0
        print "pieces -----  #{pieces}\n"
        
        1.upto(pieces) do |i|
          last = start+mid
          last = last-1 unless len % pieces >= i
          chunks << data[start..last] || []
          start = last+1
        end
        chunks
      end
      
      def get(path = '/', auth_token = nil)
        @faraday.get do |req|
          req.url path, :auth_token => auth_token||CV_API_KEY
          req.headers['Content-Type'] = 'application/json'
        end
      end

    end
  end
end
