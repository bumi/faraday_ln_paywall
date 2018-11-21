require "bundler/setup"
require "faraday_ln_paywall"
require "faraday"

conn = Faraday.new(:url => 'https://fourohtwo.herokuapp.com') do |faraday|
  faraday.use FaradayLnPaywall::Middleware, {
    max_amount: 1000,
    timeout: 300
  }
  faraday.adapter  Faraday.default_adapter
end
puts conn.get("/402").body
