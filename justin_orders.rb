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

      puts "Starting all shopify resources download"
      shop_url = "https://#{@api_key}:#{@password}@#{@shopname}.myshopify.com/admin"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2020-04'
      ShopifyAPI::Base.timeout = 180

      order_count = ShopifyAPI::Order.count( created_at_min: '2020-07-01', created_at_max: '2020-07-20', status: 'any')
      puts "We have #{order_count} orders"
      num_orders = 0

      orders = ShopifyAPI::Order.find(:all, params: {limit: 250, created_at_min: '2020-07-01', created_at_max: '2020-07-20', status: 'any'})

      #First page
      orders.each do |myord|
        puts "#{myord.id}, #{myord.name}, #{myord.fulfillments&.first&.tracking_numbers.inspect}, #{myord.fulfillments&.first&.tracking_urls.inspect}"
        num_orders += 1

      end
      
      shopify_api_throttle

      #next pages
      while orders.next_page?
        orders = orders.fetch_next_page

        orders.each do |myord|
            puts "#{myord.id}, #{myord.name}, #{myord.fulfillments&.first&.tracking_numbers.inspect}, #{myord.fulfillments&.first&.tracking_urls.inspect}"
            num_orders += 1
        end
      end
        shopify_api_throttle
        puts "We have #{num_orders} downloaded"

    end

 end
end