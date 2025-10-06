# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Tiktok
  module Open
    module Sdk
      # HTTP client utilities for TikTok Open SDK.
      #
      # Provides methods to perform HTTP requests with support for GET and POST.
      module HttpClient
        extend self

        # Supported HTTP methods.
        SUPPORTED_METHODS = %i[get post].freeze

        # Performs an HTTP request.
        #
        # @param method [Symbol] The HTTP method (:get, :post).
        # @param url [String] The request URL.
        # @param params [Hash] Query parameters for GET requests.
        # @param headers [Hash] HTTP headers.
        # @param body [Hash, nil] Request body for POST requests.
        # @return [Net::HTTPResponse] The HTTP response object.
        # @raise [ArgumentError] If the method is not supported.
        def request(method, url, params: {}, headers: {}, body: nil)
          ensure_supported_method!(method)

          uri       = URI(url)
          uri.query = URI.encode_www_form(params) if method == :get && params.any?

          http              = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl      = uri.scheme == 'https'
          http.read_timeout = 10
          http.open_timeout = 5
          http_request      = build_http_request(method, uri, headers, body)

          http.request(http_request)
        end

        # Performs a POST HTTP request.
        #
        # @param url [String] The request URL.
        # @param params [Hash] Query parameters.
        # @param headers [Hash] HTTP headers.
        # @param body [Hash, nil] Request body.
        # @return [Net::HTTPResponse] The HTTP response object.
        def post(url, params: {}, headers: {}, body: nil)
          request(:post, url, params: params, headers: headers, body: body)
        end

        # Performs a GET HTTP request.
        #
        # @param url [String] The request URL.
        # @param params [Hash] Query parameters.
        # @param headers [Hash] HTTP headers.
        # @return [Net::HTTPResponse] The HTTP response object.
        def get(url, params: {}, headers: {})
          request(:get, url, params: params, headers: headers)
        end

        private

        # Ensures the HTTP method is supported.
        #
        # @param method [Symbol] The HTTP method.
        # @return [true] If the method is supported.
        # @raise [ArgumentError] If the method is not supported.
        def ensure_supported_method!(method)
          return true if SUPPORTED_METHODS.include?(method)

          raise ArgumentError, "Unsupported method: #{method}"
        end

        # Assigns the request body based on content type.
        #
        # @param request [Net::HTTPRequest] The HTTP request object.
        # @param body [Hash] The request body.
        # @param content_type [String] The content type header.
        # @return [Net::HTTPRequest] The modified request object.
        # @raise [ArgumentError] If the content type is unsupported.
        def assign_body!(request, body, content_type)
          case content_type
          when 'application/x-www-form-urlencoded'
            request.set_form_data(body)
          when 'application/json', 'application/json; charset=UTF-8'
            request.body = body.to_json
          else
            raise ArgumentError, "Unsupported content type: #{content_type}"
          end

          request
        end

        # Builds the Net::HTTP request object.
        #
        # @param method [Symbol] The HTTP method.
        # @param uri [URI] The request URI.
        # @param headers [Hash] HTTP headers.
        # @param body [Hash, nil] The request body.
        # @return [Net::HTTPRequest] The HTTP request object.
        def build_http_request(method, uri, headers, body)
          klass   = Net::HTTP.const_get(method.capitalize)
          request = klass.new(uri, headers)

          body ? assign_body!(request, body, headers[:'Content-Type']) : request
        end
      end
    end
  end
end
