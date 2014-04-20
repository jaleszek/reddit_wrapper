require "addressable/uri"
require 'curb'
require 'json'

module RedditAPI 
	class Pinger
		attr_reader :resource, :action, :url, :http_method

		BASE_URL = 'http://www.reddit.com'
		FUNCTIONAL_ARGS = [:resource, :action]
		FORMAT = '.json'
		ROUTING = {
			"article/popular" => {
				url: "#{BASE_URL}/subreddits/popular#{FORMAT}",
				http_method: :get
			},
			"article/new" => {
				url: "#{BASE_URL}/subreddits/new#{FORMAT}",
				http_method: :get
			},
			"article/search" => {
				url: "#{BASE_URL}/subreddits/search#{FORMAT}",
				http_method: :get
			},
			"link/search" => {
				url: "#{BASE_URL}/r/subreddit/search#{FORMAT}",
				http_method: :get
			}
		}

		def initialize(args= {})
			FUNCTIONAL_ARGS.each do |arg|
				instance_variable_set("@#{arg}", args[arg])
			end

			@additional_args = args.select{|k, _| !FUNCTIONAL_ARGS.include?(k)}

			compose_url
		end

		def execute
			Curl.send(ROUTING[resource_ident][:http_method], url)
		end

		private

		def compose_url
			uri = Addressable::URI.parse ROUTING[resource_ident][:url]

			uri.query_values = @additional_args

			@url = uri.to_s
		end

		def resource_ident
			"#{@resource}/#{@action}"
		end
	end

	module ResponseWrapper
		private
		def wrap_me(response)
			if response
				json = JSON.parse(response.body_str)
				return json['data']['children'].map do |article|
					new article['data']
				end
			end
			[]
		end		
	end

	class Resource

		attr_reader :input

		def initialize(json)
			@input = json
			json.each do |k,v|
				self.class.send(:define_method, "data_#{k}"){ v }
			end
		end

		def self.slug(method_name, additional_args)
			class_name = name.split('::').last.downcase
			additional_args.merge! resource: class_name , action: method_name
		end

		def attributes
			input.keys
		end

		extend ResponseWrapper
	end

	class Article < Resource
		def self.popular(args = {})
			response = Pinger.new(slug(__method__, args)).execute
			wrap_me(response)
		end
	end

	class Link < Resource
		def self.search(args = {})
			response = Pinger.new(slug(__method__, args)).execute
			wrap_me(response)
		end
	end
end