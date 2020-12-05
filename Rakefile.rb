require 'active_record'
require 'sinatra/activerecord/rake'

require_relative 'justin_orders'

namespace :pull_orders do
    desc 'get all orders'
    task :get_all_orders do |t|
        PullShopifyOrders::ShopifyGetter.new.get_orders
    end

end