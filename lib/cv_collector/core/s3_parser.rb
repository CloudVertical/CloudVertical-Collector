class S3Parser
  FIELDS = [:bucket_owner, :bucket, :timestamp, :remote_ip, :requester, :request_id, :operation, :key, :request_uri, :http_status, :error_code, :bytes_sent, :object_size, :total_time, :turnaround_time, :referer, :user_agent]
  
  TIMESTAMP_PARTS = {
    'a' => '(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)',
    'b' => '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
    'y' => '\d{2}', 'Y' => '\d{4}', 'm' => '\d{2}', 'd' => '\d{2}',
    'H' => '\d{2}', 'M' => '\d{2}', 'S' => '\d{2}', 'k' => '(?:\d| )\d',
    'z' => '(?:[+-]\d{4}|[A-Z]{3,4})',
    'Z' => '(?:[+-]\d{4}|[A-Z]{3,4})',
    '%' => '%'
  }
  class << self
    def add_blank_option(regexp, blank)
      case blank
        when String; Regexp.union(regexp, Regexp.new(Regexp.quote(blank)))
        when true;   Regexp.union(regexp, //)
        else regexp
      end
    end
  
    def timestamp(format_string, blank = false)
      regexp = ''
      format_string.scan(/([^%]*)(?:%([A-Za-z%]))?/) do |literal, variable|
        regexp << Regexp.quote(literal)
        if variable
          if TIMESTAMP_PARTS.has_key?(variable)
            regexp << TIMESTAMP_PARTS[variable]
          else
            raise "Unknown variable: %#{variable}"
          end
        end
      end

      add_blank_option(Regexp.new(regexp), blank)
    end

    def ip_address(blank = false)

      # IP address regexp copied from Resolv::IPv4 and Resolv::IPv6, 
      # but adjusted to work for the purpose of request-log-analyzer.
      ipv4_regexp                     = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
      ipv6_regex_8_hex                = /(?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}/
      ipv6_regex_compressed_hex       = /(?:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::(?:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)/
      ipv6_regex_6_hex_4_dec          = /(?:(?:[0-9A-Fa-f]{1,4}:){6})#{ipv4_regexp}/
      ipv6_regex_compressed_hex_4_dec = /(?:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::(?:(?:[0-9A-Fa-f]{1,4}:)*)#{ipv4_regexp}/
      ipv6_regexp                     = Regexp.union(ipv6_regex_8_hex, ipv6_regex_compressed_hex, ipv6_regex_6_hex_4_dec, ipv6_regex_compressed_hex_4_dec)

      add_blank_option(Regexp.union(ipv4_regexp, ipv6_regexp), blank)
    end
  
    def run(file)
      regexp = /^([^\ ]+) ([^\ ]+) \[(#{timestamp('%d/%b/%Y:%H:%M:%S %z')})?\] (#{ip_address}) ([^\ ]+) ([^\ ]+) (\w+(?:\.\w+)*) ([^\ ]+) "([^"]+)" (\d+) ([^\ ]+) ([\d-]+) ([\d-]+) ([\d-]+) ([\d-]+) "([^"]*)" "([^"]*)"/
      file[:file].split("\n").map{ |line|
        hash = {}
        line = line.scan(regexp).first
        if line
          line.each_with_index do |field, i|
            hash[FIELDS[i]]=field
          end
        end
        hash unless hash.empty?
      }.compact
    end
  end

end




