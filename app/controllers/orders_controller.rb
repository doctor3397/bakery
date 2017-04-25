class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token
  require 'net/http'


  def index

    @available_cookies = nil
    @orders = []
    i = 1

    # Read all orders from the paginated API.
    while true
      result = Net::HTTP.get(URI.parse("https://backend-challenge-fall-2017.herokuapp.com/orders.json?page=#{i}"))
      result = JSON.parse(result)

      break if result["orders"].length == 0

      # Setting orders and remove any order without cookies
      @orders +=  get_cookie_orders(result)

      # Get the available_cookies
      @available_cookies = result["available_cookies"] if @available_cookies == nil
      i += 1
    end

    # Prioritize fulfilling orders with the highest amount of cookies.
    # If orders have the same amount of cookies, prioritize the order with the lowest ID.
    sort_by_cookie_amount(@orders)

    # Check every Cookie order with the amount of cookie
    # If an order has an amount of cookies bigger than the remaining cookies, skip the order.
    @unfulfilled_orders, @available_cookies = get_unfulfilled_cookie_orders(@orders, @available_cookies)

    respond_to do |format|
      format.json do render json:
        {
          "remaining_cookies": @available_cookies,
          "unfulfilled_orders": @unfulfilled_orders
        }
      end
      format.html
    end
  end
end

private
def sort_by_cookie_amount(orders)
  orders.sort! do |a, b|
    b[:product]["amount"] <=> a[:product]["amount"]
  end
end

def get_unfulfilled_cookie_orders(orders, available_cookies)
  unfulfilled_orders = []
  orders.each do |order|
    if order[:product]["amount"] <= available_cookies
      available_cookies -= order[:product]["amount"]
    else
      unfulfilled_orders << order[:id]
    end
  end
  return unfulfilled_orders, available_cookies
end

def get_cookie_orders(result)
  orders = []
  result["orders"].each do |order|
    order["products"].each do |product|
      if product["title"].include?("Cookie")
        orders << { "id": order["id"],
                     "product": product }
      end
    end
  end
  return orders
end
