require 'grpc'
require 'lightning/invoice'

ENV['GRPC_SSL_CIPHER_SUITES'] = "HIGH+ECDSA"

module FaradayLnPaywall
  class PaymentError < StandardError; end

  class Middleware <  Faraday::Middleware

    def initialize(app, options = {})
      super(app)
      @options = options
      @options[:address] ||= 'localhost:10009'
      @options[:timeout] ||= 5
      @options[:credentials] ||= File.read(File.expand_path(@options[:credentials_path] || "~/.lnd/tls.cert"))
      @options[:macaroon] ||= begin
        macaroon_binary = ::File.read(::File.expand_path(@options[:macaroon_path] || "~/.lnd/data/chain/bitcoin/testnet/admin.macaroon"))
        macaroon_binary.each_byte.map { |b| b.to_s(16).rjust(2,'0') }.join
      end
      @lnd_client = Lnrpc::Lightning::Stub.new(@options[:address], GRPC::Core::ChannelCredentials.new(@options[:credentials]))
    end

    def payment_requested?(env)
      env[:status] == 402 && env[:response_headers]['Content-Type'] == "application/vnd.lightning.bolt11"
    end

    def validate_invoice!(invoice)
      if !@options[:max_amount].nil? && @options[:max_amount] < invoice.amount
        raise PaymentError, "invoice amount greater than expected maximum of #{@options[:max_amount]}"
      end
      if !invoice.expiry.nil? && Time.now.to_i > invoice.timestamp + invoice.expiry.to_i
        raise PaymentError, "invoice expired"
      end
    end

    def pay(env)
      invoice = Lightning::Invoice.parse(env.body)
      validate_invoice!(invoice)

      Timeout::timeout(@options[:timeout], PaymentError, "payment execution expired") do
        @lnd_client.send_payment_sync(
          Lnrpc::SendRequest.new(payment_request: env.body),
          { metadata: { macaroon: @options[:macaroon] }}
        )
      end
    end

    def call(request_env)
      @app.call(request_env).on_complete do |response_env|
        if payment_requested?(response_env)
          payment = pay(response_env)
          if payment && payment.payment_error == ""
            preimage = payment.payment_preimage.each_byte.map { |b| b.to_s(16).rjust(2, '0') }.join
            request_env[:request_headers].merge!('X-Preimage' => preimage)
            @app.call(request_env)
          else
            raise PaymentError, payment.payment_error
          end
        end
      end
    end

  end
end

