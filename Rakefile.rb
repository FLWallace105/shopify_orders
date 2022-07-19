require 'active_record'
require 'sinatra/activerecord/rake'

require_relative 'justin_orders'
require_relative 'cancel_orders'

namespace :pull_orders do
    desc 'get all orders'
    task :get_all_orders do |t|
        PullShopifyOrders::ShopifyGetter.new.get_orders
    end

    desc 'get testing orders'
    task :get_testing_orders do |t|
        PullShopifyOrders::ShopifyGetter.new.get_testing_orders
    end

end

namespace :canceled_orders do
    desc 'get canceled orders'
    task :get_all_orders_for_cancelation, :shopname do |t, args|
        shopname = args[:shopname]
        PullOrders::OrderGetter.new.get_orders(shopname)
    end


end


namespace :pavan_orders do

    desc "Read in Pavan provided csv and get order information, write out to CSV."
    task :get_pavan_orders, :pavan_file do |t, args|
        myfile = args['pavan_file']
        PullShopifyOrders::ShopifyGetter.new.get_pavan_orders(myfile)
end


end