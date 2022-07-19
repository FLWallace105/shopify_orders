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

module PullOrders
  class OrderGetter
    include ShopifyThrottle

    def initialize
      @shopname = ENV['SHOPIFY_SHOP_NAME']
      @api_key = ENV['SHOPIFY_API_KEY']
      @password = ENV['SHOPIFY_API_PASSWORD']
      @marika_shop_name = ENV['MARIKA_SHOP_NAME']
      @marika_api_key = ENV['MARIKA_API_KEY']
      @marika_password = ENV['MARIKA_API_PASSWORD']

      @zobha_shop_name = ENV['ZOBHA_SHOP_NAME']
      @zobha_api_key = ENV['ZOBHA_API_KEY']
      @zobha_password = ENV['ZOBHA_API_PASSWORD']

      @wildfox_shop_name = ENV['WILDFOX_SHOP_NAME']
      @wildfox_api_key = ENV['WILDFOX_API_KEY']
      @wildfox_password = ENV['WILDFOX_API_PASSWORD']

      @threedots_shop_name = ENV['THREEDOTS_SHOP_NAME']
      @threedots_api_key = ENV['THREEDOTS_API_KEY']
      @threedots_password = ENV['THREEDOTS_API_PASSWORD']

      @my_min = '2021-09-09'
      @my_max = '2021-09-15'

      
    end

    def get_orders(shopname)
      case shopname
      when "ellieactive"
        temp_shopname = @shopname
        temp_api_key = @api_key
        temp_password = @password

      when "marikaactive"
        temp_shopname = @marika_shop_name
        temp_api_key = @marika_api_key
        temp_password = @marika_password

      when "zobha"
        temp_shopname = @zobha_shop_name
        temp_api_key = @zobha_api_key
        temp_password = @zobha_password

      when "wildfox"
        temp_shopname = @wildfox_shop_name
        temp_api_key = @wildfox_api_key
        temp_password = @wildfox_password

      when "threedots"
        temp_shopname = @threedots_shop_name
        temp_api_key = @threedots_api_key
        temp_password = @threedots_password

      end

      File.delete("#{temp_shopname}_orders_cancel.csv") if File.exist?("#{temp_shopname}_orders_cancel.csv")
      puts "Starting all shopify resources download"
      column_header = ["order_id", "order_name", "order_email"]
      CSV.open("#{temp_shopname}_orders_cancel.csv",'a+', :write_headers=> true, :headers => column_header) do |hdr|
            column_header = nil



      shop_url = "https://#{temp_api_key}:#{temp_password}@#{temp_shopname}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2020-04'
      ShopifyAPI::Base.timeout = 180

      order_count = ShopifyAPI::Order.count( created_at_min: @my_min, created_at_max: @my_max, status: 'cancelled')
      puts "We have #{order_count} orders"
      num_orders = 0

      orders = ShopifyAPI::Order.find(:all, params: {limit: 250, created_at_min: @my_min, created_at_max: @my_max, status: 'cancelled'})

      #First page
      orders.each do |myord|
        #puts "#{myord.id}, #{myord.name}, #{myord.fulfillments&.first&.tracking_numbers.inspect}, #{myord.fulfillments&.first&.tracking_urls.inspect}"
        puts "#{myord.id}, #{myord.name}, #{myord.email}"
        #puts myord.line_items.inspect
        csv_data_out = [myord.id, myord.name, myord.email ]
        hdr << csv_data_out
        


        num_orders += 1

      end
      
      shopify_api_throttle

      

      #next pages
      while orders.next_page?
        orders = orders.fetch_next_page

        orders.each do |myord|
          #puts "#{myord.id}, #{myord.name}, #{myord.fulfillments&.first&.tracking_numbers.inspect}, #{myord.fulfillments&.first&.tracking_urls.inspect}"
          puts "#{myord.id}, #{myord.name}, #{myord.email}"
          #puts myord.line_items.inspect
          csv_data_out = [myord.id, myord.name, myord.email ]
          hdr << csv_data_out
          
  
  
          num_orders += 1
  
        end
      end
        shopify_api_throttle
        puts "We have #{num_orders} downloaded"
    end
    #above CSV part

  end

 end
end