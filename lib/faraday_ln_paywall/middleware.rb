require 'lnrpc'
require 'lightning/invoice'

module FaradayLnPaywall
  class PaymentError < StandardError; end

  class Middleware <  Faraday::Middleware

    def initialize(app, options = {})
      super(app)
      @options = options
      @options[:timeout] ||= 30
      @lnd_client = Lnrpc::Client.new(@options)
    end

    def payment_requested?(env)
      env[:status] == 402 && env[:response_headers]['Content-Type'] == "application/vnd.lightning.bolt11"
    end

    def validate_invoice!(invoice)
      if !@options[:max_amount].nil? && @options[:max_amount] < invoice_amount_in_satoshi(invoice)
        raise PaymentError, "invoice amount greater than expected maximum of #{@options[:max_amount]}"
      end
      if !invoice.expiry.nil? && Time.now.to_i > invoice.timestamp + invoice.expiry.to_i
        raise PaymentError, "invoice expired"
      end
    end

    def pay(env)
      invoice = Lightning::Invoice.parse(env.body)
      log(:info, "amount: #{invoice_amount_in_satoshi(invoice)} description: #{invoice.description} payment_hash: #{invoice.payment_hash}")
      validate_invoice!(invoice)

      Timeout::timeout(@options[:timeout], PaymentError, "payment execution expired") do
        log(:info, "sending payment")
        @lnd_client.send_payment_sync(payment_request: env.body)
      end
    end

    def call(request_env)
      original_call = request_env.dup
      response = @app.call(request_env)
      response.on_complete do |response_env|
        if payment_requested?(response_env)
          log(:info, "payment requested")
          payment = pay(response_env)
          if payment && payment.payment_error == ""
            preimage = payment.payment_preimage.each_byte.map { |b| b.to_s(16).rjust(2, '0') }.join # .unpack("H*")
            log(:info, "paid preimage: #{preimage}")
            original_call[:request_headers].merge!('X-Preimage' => preimage)
            log(:info, "sending original request with preimage header")
            response = @app.call(original_call)
          else
            log(:error, "payment error #{payment.payment_error}")
            raise PaymentError, payment.payment_error
          end
        end
      end
      response
    end

    # todo move to Lightning/invoice gem
    def invoice_amount_in_satoshi(invoice)
      return if invoice.amount.nil?
      multi = {
        'm' => 0.001,
        'u' => 0.000001,
        'n' => 0.000000001,
        'p' => 0.000000000001
      }[invoice.multiplier]

      (invoice.amount * multi * 100000000).to_i # amount in bitcoin * 100000000
    end

    def log(level, message)
      @options[:logger].send(level, message) if @options[:logger]
    end
  end
end

