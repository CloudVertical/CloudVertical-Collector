require 'base64'
require 'json'
module CvClient
  module Provider
    module Aws
      class Billing < CvClient::Provider::Aws::Base
        
        AWS_BILLING_END_POINT = "https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=activity-summary"
        VENDOR = "aws"
        TYPE = "billing"
        PATH = "/v01/statements.json"
        WEBSITE_PATH = "/v01/statements/create_aws.json"
        JSON_PATH = "/v01/statements/create_aws2.json"
        
        def fetch_data()
          # init data
          timestamp = get_timestamp
          agent = init_agent
          page = agent.page
          account_ref = get_acccount_number(page)
          is_consolidated = consolidated_billling?(page)
          @stored_timestamp = new?
          @periods = page.search("select[name='statementTimePeriod']").children.map{|period| 
            v = period.attributes['value'].value.to_i; 
            [v, Time.at(v).utc.end_of_month] if v > 0
          }.compact
          # end init data
          
          if is_consolidated    
            parent_account_ref = account_ref
            caccounts = consolidated_accounts(page)
            caccounts.each do |caccount|
              consolidated_data = []
              opts = {:account_number => caccount[:account_number]}
              download_for_periods(agent, opts).
                merge({timestamp => download_data(agent, opts)}).
                each do |period_timestamp, statement_data|
                  consolidated_data << common_data.merge({:data => statement_data, 
                                                          :timestamp => period_timestamp, 
                                                          :account_ref => caccount[:account_number],
                                                          :parent_account_ref => parent_account_ref})
              end
              send(consolidated_data, JSON_PATH)
            end
          end
          
          data = []
          download_for_periods(agent).
            merge({timestamp => page.content}).
            each do |period_timestamp, statement_data|
              data << common_data.merge({:data => Base64.encode64(statement_data), 
                                        :timestamp => period_timestamp, 
                                        :account_ref => account_ref})
          end
          send(data, WEBSITE_PATH)
          {}
        rescue NoMethodError => e
          p e
          p e.backtrace
          # notify ?
        rescue Encoding::UndefinedConversionError => e
          p e
          p e.backtrace
          # pass
        rescue => e
          p e
          p e.backtrace
        end
        
        def parse_data
        end
        
        def send(data = nil, path = nil)
          connection.post({:data => data||@data, :auth_token => @auth_token}, path||PATH)
        rescue => e
          p e
          p e.backtrace
          # pass          
        end
        
        private
        
        def init_agent(page = AWS_BILLING_END_POINT)
          agent = Mechanize.new
          agent.user_agent_alias = "Mac Safari"
          agent.get(page)
          form = agent.page.form("signIn")
          form.email = @email
          form.password = @password
          form.submit
          return agent
        end
        
        def consolidated_billling?(page)
          page.search("div[id='payer_activity_table_tab_content']").any?
        end
        
        def get_acccount_number(page)
          r = page.search("span[class='txtxxsm']")
          txt = r.select{|rr| rr.children.text.match(/Account Number/)}[0].text
          account_number = txt.match(/([\d+-]+)/)[1].gsub("-","")
          return account_number  
        end
        
        def consolidated_accounts(page)
          accounts = []
          spans = page.search("//span[substring(@id, 1, 27) = 'linked_account_toggle_name_']")
          spans.each do |span|
            accounts << {:account_number => span.attributes["id"].value.split('_')[-1], :account_name => span.children.text}
          end
          return accounts
        end
        
        def download_data(agent, options = {})
          url = AWS_BILLING_END_POINT
          if options.has_key?(:account_number) && options[:account_number]
            url += "&view-linked-bill-summary-button.x=yes&linkedAccountId=#{options[:account_number]}"
          end
          if options.has_key?(:statement_period) && options[:statement_period]
            url += "&statementTimePeriod=#{options[:statement_period]}"
          end
          page = agent.get(url)
          return page.content
        end
        
        def download_for_periods(agent, options = {})
          data = {}
          @periods.each{ |period, timestamp|  
            data[timestamp] = download_data(agent, options.merge({:statement_period => period})) if timestamp < @stored_timestamp
          }
          data
        end
                  
        def common_data()
          return {:provider => PROVIDER, 
                  :cloud_connection_id => @cloud_connection_id,
                  :tags => parse_tags([])}
        end
        
        def new?
          body = connection.get("/v01/statements/is_new?limit=1&format=json&cloud_connection_id=#{@cloud_connection_id}", @auth_token).body
          stored_date = JSON.parse(body)
          stored_date.size > 0 ? Time.parse(stored_date.first["timestamp"]) : Time.now.utc
        end

      end
    end
  end
end
