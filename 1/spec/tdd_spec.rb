require 'spec_helper'
require 'debugger'

describe RedditAPI::Pinger do

	before{ VCR.insert_cassette 'pinger'}
	after{ VCR.eject_cassette }
	subject{described_class.new(pinger_args)}

	describe '.initialize' do
		subject{ described_class }
		it 'assigns arguments to instance variables' do
			instance = subject.new(action: :popular, resource: :article)
			expect(instance.resource).to eq(:article)
			expect(instance.action).to eq(:popular)
		end
	end

	describe '#url' do

	  context 'subreddits/popular' do
	  	let(:pinger_args){ { action: :popular, resource: :article, limit: 10} }

	  	it 'collects proper url' do
	  		expect(subject.url).to eq('http://www.reddit.com/subreddits/popular.json?limit=10')
	  	end
		end

		context 'subreddits/new' do
			let(:pinger_args) { {action: :new, resource: :article, limit: 100, now: true }}
			it 'collects proper url' do
				expected_uri = 'http://www.reddit.com/subreddits/new.json?limit=100&now=true'
				expect(subject.url).to eq(expected_uri)
			end
		end
	end

	describe '#execute' do
		let(:pinger_args) { { action: :new, resource: :article, limit: 10, q: 'poland'} }

		context 'GET' do
			it 'makes http request' do
				expect(Curl).to receive(:get).with(subject.url)
				subject.execute
			end
		end
	end
end

describe RedditAPI::Article do
	subject{ described_class }
	before{ VCR.insert_cassette 'article'}
	after{ VCR.eject_cassette }

	describe '.popular' do
		it 'returns array of Articles' do
			popular = subject.popular(limit: 10)

			expect(popular.size).to eq(10)
			expect(popular.all?{|p| p.is_a?(subject)}).to be_true
		end
	end

	describe '.initialize' do
		it 'stores article arguments as data - proxy methods' do
			ins = subject.new(a: 1, b: 2, c: 3)
			expect(ins.data_a).to eq(1)
			expect(ins.data_b).to eq(2)
			expect(ins.data_c).to eq(3)
		end

	  it 'stores original JSON input' do
	  	input = {a: 1, b: 2, c: 3}
	  	expect(subject.new(input).input).to eq(input)
	  end
	end
end

describe RedditAPI::Link do
	before{ VCR.insert_cassette 'link'}
	after{ VCR.eject_cassette }
	subject{ described_class }

	describe '.search' do
		it 'returns array of searched links' do
		  ins = subject.search(q: 'poland', limit: 10)
		  expect(ins.size).to eq(10)
		  expect(ins.all?{|l| l.is_a?(subject)}).to be_true
		end
	end
end