# FaradayLnPaywall

This is a [Faraday](https://github.com/lostisland/faraday#readme) middleware that handles payment requests by the server
and sends Bitcoin [lightning payments](https://lightning.network/). 


## How does it work? 

This Faraday middleware checks if the server responds with a `402 Payment Required` HTTP status code and 
a lightning invoice ([BOLT11](https://github.com/lightningnetwork/lightning-rfc/blob/master/11-payment-encoding.md)).
If so it pays the invoice through the connected [lnd node](https://github.com/lightningnetwork/lnd/) and performs
a second request with the proof of payment. 

### How does the server side look like?

Have a look at [@philippgille's related server implementation in Go](https://github.com/philippgille/ln-paywall).


## Requirements

The middleware uses the gRPC service provided by the [Lightning Network Daemon(lnd)](https://github.com/lightningnetwork/lnd/). 
A running node with funded channels is required. Details about lnd can be found on their [github page](https://github.com/lightningnetwork/lnd/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday_ln_paywall'
```

## Usage

Simply use the `FaradayLnPaywall::Middleware` in your Faraday connection:

```ruby
conn = Faraday.new(:url => 'https://api.lightning.ws') do |faraday|
  faraday.use FaradayLnPaywall::Middleware, { max_amount: 100 }
  faraday.adapter  Faraday.default_adapter
end
puts conn.get("/translate?text=Danke&to=en").body

```

## Configuration

The middleware accepts the following configuration options: 

* `max_amount`: the maximum amount of an invoice that will automatically be paid. Raises a `FaradayLnPaywall::PaymentError` if the server request a higher amount
* `address`: the address of the lnd gRPC service( default: `localhost:10009`)
* `credentials`: path to the tls.cert (default: `~/.lnd/tls.cert`)
* `macaroon`: path to the macaroon path (default: `~/.lnd/data/chain/bitcoin/testnet/admin.macaroon`)


## What is the Lightning Network?

The [Lightning Network](https://en.wikipedia.org/wiki/Lightning_Network) allows to send real near-instant microtransactions with extremely low fees. 
It is a second layer on top of the Bitcoin network (and other crypto currencies). 
Thanks to this properties it can be used to monetize APIs. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bumi/faraday_ln_paywall.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
