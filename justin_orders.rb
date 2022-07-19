#justin_orders.rb
require 'dotenv'
require 'httparty'
require 'shopify_api'
require 'active_record'
require 'sinatra/activerecord'
require 'logger'

Dotenv.load
Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'models', '*.rb')].each { |file| require file }

module PullShopifyOrders
  class ShopifyGetter
    include ShopifyThrottle

    def initialize
      @shopname = ENV['SHOPIFY_SHOP_NAME']
      @api_key = ENV['SHOPIFY_API_KEY']
      @password = ENV['SHOPIFY_API_PASSWORD']

      
    end

    def get_orders

      File.delete('orders_ellie_picks.csv') if File.exist?('orders_ellie_picks.csv')
      puts "Starting all shopify resources download"
      column_header = ["order_id", "order_name", "order_email", "order_product_collection", "order_created_at"]
      CSV.open('orders_ellie_picks.csv','a+', :write_headers=> true, :headers => column_header) do |hdr|
            column_header = nil



      shop_url = "https://#{@api_key}:#{@password}@#{@shopname}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2020-04'
      ShopifyAPI::Base.timeout = 180

      order_count = ShopifyAPI::Order.count( created_at_min: '2022-07-09T20:59:59-08:00', created_at_max: '2022-07-11T23:59:59-08:00', status: 'any')
      puts "We have #{order_count} orders"
      num_orders = 0

      orders = ShopifyAPI::Order.find(:all, params: {limit: 250, created_at_min: '2022-07-09T20:59:59-08:00', created_at_max: '2022-07-11T23:59:59-08:00', status: 'any'})

      bad_order_attributes = []

      #First page
      orders.each do |myord|
        #puts "#{myord.id}, #{myord.name}, #{myord.fulfillments&.first&.tracking_numbers.inspect}, #{myord.fulfillments&.first&.tracking_urls.inspect}"
        # puts "#{myord.id}, #{myord.name}, #{myord.customer.attributes['default_address'].attributes['country_code']}, #{myord.customer.attributes['default_address'].attributes['province_code']}"
        # if (myord.customer.attributes['default_address'].attributes['country_code'] == nil) || (myord.customer.attributes['default_address'].attributes['province_code'] == nil)
        #   bad_order_attributes << {"order_name" => myord.name}

        # end
        # next
        puts "#{myord.id}, #{myord.name}, #{myord.email}"
        #puts myord.line_items.inspect
        myord.line_items.each do |line_item|
          #puts line_item.attributes.inspect
          line_item.attributes.each do |myattr|
            #puts myattr.inspect
            if myattr.first == "properties"
              puts myattr[1].inspect
              if myattr[1] != []
                temp_prod_coll = myattr[1].select { |x| x.attributes['name'] == "product_collection"}
                #puts temp_prod_coll.inspect
                if temp_prod_coll != []
                  my_prod_collection = temp_prod_coll.first.attributes['value']
                else
                  my_prod_collection = "BLANK PRODUCT COLLECTION"
                end
                #puts my_prod_collection
                if (my_prod_collection =~ /ellie\spick/i) || my_prod_collection == "BLANK PRODUCT COLLECTION"
                  puts "FOUND: Ellie Picks or blank product collection"
                  csv_data_out = [myord.id, myord.name, myord.email, my_prod_collection, myord.created_at ]
                  hdr << csv_data_out
                end

              end
            end

          end

        end


        num_orders += 1

      end
      
      shopify_api_throttle

      

      

      #next pages
      while orders.next_page?
        orders = orders.fetch_next_page

        orders.each do |myord|
            #puts "#{myord.id}, #{myord.name}, #{myord.fulfillments&.first&.tracking_numbers.inspect}, #{myord.fulfillments&.first&.tracking_urls.inspect}"
            # puts "#{myord.id}, #{myord.name}, #{myord.customer.attributes['default_address'].attributes['country_code']}, #{myord.customer.attributes['default_address'].attributes['province_code']}"
            # if (myord.customer.attributes['default_address'].attributes['country_code'] == nil) || (myord.customer.attributes['default_address'].attributes['province_code'] == nil)
            #   bad_order_attributes << {"order_name" => myord.name}
    
            # end
            # #puts "going to next one"
            # next
            puts "#{myord.id}, #{myord.name}. #{myord.email}"
            num_orders += 1
            myord.line_items.each do |line_item|
              #puts line_item.attributes.inspect
              line_item.attributes.each do |myattr|
                #puts myattr.inspect
                if myattr.first == "properties"
                  puts myattr[1].inspect
                  if myattr[1] != []
                    temp_prod_coll = myattr[1].select { |x| x.attributes['name'] == "product_collection"}
                    #puts temp_prod_coll.inspect
                    if temp_prod_coll != []
                      my_prod_collection = temp_prod_coll.first.attributes['value']
                      #puts my_prod_collection
                      if my_prod_collection =~ /ellie\spick/i
                        puts "FOUND: Ellie Picks"
                        csv_data_out = [myord.id, myord.name, myord.email, my_prod_collection ]
                        hdr << csv_data_out
                      end
                    end
    
                  end
                end
    
              end
    
            end
        end
      end
        shopify_api_throttle
        puts "We have #{num_orders} downloaded"
        
    end
    #above CSV part
    

    end



    def get_pavan_orders(myfile)
      puts "myfile = #{myfile}"
      File.delete('pavan_orders_ellie_picks.csv') if File.exist?('pavan_orders_ellie_picks.csv')

      column_header = ["order_id", "order_name", "order_email", "order_product_collection", "order_created_at"]
      CSV.open('pavan_orders_ellie_picks.csv','a+', :write_headers=> true, :headers => column_header) do |hdr|
            column_header = nil

      shop_url = "https://#{@api_key}:#{@password}@#{@shopname}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2020-04'
      ShopifyAPI::Base.timeout = 180

      CSV.foreach(myfile, :encoding => 'ISO8859-1:utf-8', :headers => true) do |row|
        puts row.inspect
        my_pick_ticket = row['Pick Ticket']
        my_order = ShopifyAPI::Order.find(my_pick_ticket)
        puts my_order.inspect
        puts "------------"
        puts "#{my_order.id}, #{my_order.name}, #{my_order.email}"
        #puts myord.line_items.inspect
        my_order.line_items.each do |line_item|
          #puts line_item.attributes.inspect
          line_item.attributes.each do |myattr|
            #puts myattr.inspect
            if myattr.first == "properties"
              puts myattr[1].inspect
              if myattr[1] != []
                temp_prod_coll = myattr[1].select { |x| x.attributes['name'] == "product_collection"}
                #puts temp_prod_coll.inspect
                if temp_prod_coll != []
                  my_prod_collection = temp_prod_coll.first.attributes['value']
                else
                  my_prod_collection = "BLANK PRODUCT COLLECTION"
                end
                #puts my_prod_collection
                if (my_prod_collection =~ /ellie\spick/i) || my_prod_collection == "BLANK PRODUCT COLLECTION"
                  puts "FOUND: Ellie Picks or blank product collection"
                  csv_data_out = [ my_order.id,  my_order.name,  my_order.email, my_prod_collection,  my_order.created_at ]
                  hdr << csv_data_out
                end

              end
            end

          end

        end


        shopify_api_throttle

      end
    end #CSV outer part


    end


    def get_testing_orders
      email_key = 'alvaro.oxandabarat@salsamobi.com'

      shop_url = "https://#{@api_key}:#{@password}@#{@shopname}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2020-04'
      ShopifyAPI::Base.timeout = 180

      my_start_month = Date.today.beginning_of_month
      my_start_month_str = my_start_month.strftime("%Y-%m-%dT00:59:59-08:00")

      my_end_month = Date.today.end_of_month
      my_end_month_str = my_end_month.strftime("%Y-%m-%dT20:59:59-08:00")

      puts "start month = #{my_start_month_str}"
      puts "end month = #{my_end_month_str}"

      order_count = ShopifyAPI::Order.count( created_at_min: my_start_month_str, created_at_max: my_end_month_str, status: 'any')

      File.delete('testing_orders_to_cancel.csv') if File.exist?('testing_orders_to_cancel.csv')
      puts "Starting all shopify resources download"
      column_header = ["order_id", "order_name", "order_email", "order_created_at"]
      CSV.open('testing_orders_to_cancel.csv','a+', :write_headers=> true, :headers => column_header) do |hdr|
            column_header = nil

      puts "We have #{order_count} orders"

      orders = ShopifyAPI::Order.find(:all, params: {limit: 250, created_at_min: my_start_month_str, created_at_max: my_end_month_str, status: 'any'})

      orders.each do |myord|
        puts "#{myord.id}, #{myord.name}. #{myord.email}"

        if myord.email == email_key
          csv_data_out = [myord.id, myord.name, myord.email,  myord.created_at ]
          hdr << csv_data_out

        end


      end

      shopify_api_throttle

      while orders.next_page?
        orders = orders.fetch_next_page

        orders.each do |myord|
          puts "#{myord.id}, #{myord.name}. #{myord.email}"

          if myord.email == email_key
            csv_data_out = [myord.id, myord.name, myord.email,  myord.created_at ]
            hdr << csv_data_out

          end

        end
        shopify_api_throttle
      end


    end
    #above CSV part



    end

 end
end