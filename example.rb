require "bundler/setup"
require "faraday_ln_paywall"
require "faraday"

conn = Faraday.new(:url => 'https://api.lightning.ws') do |faraday|
  faraday.use FaradayLnPaywall::Middleware, { max_amount: 100 }
  faraday.adapter  Faraday.default_adapter
end
puts conn.get("/translate?text=Hallo%20Welt&to=en").body
