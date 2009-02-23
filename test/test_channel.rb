require 'test/unit'
require "csp"

class ChannelTestCase < Test::Unit::TestCase

	def test_read_write
	
		writer = CSP::Process.new do |out|
			out.write "Hello" 
		end
		
		reader = CSP::Process.new do |input|
			input.read
		end
		
		c = CSP::Channel.new
		res = CSP::in_parallel do |l|
			l.add writer, c.output
			l.add reader, c.input
		end
		
		assert res == ["Hello", "Hello"]

		writer = CSP::Process.new do |out|
			out << "Hello" 
		end
		
		res = CSP::in_parallel do |l|
			l.add writer, c.output
			l.add reader, c.input
		end
		
		assert res == ["Hello", "Hello"]
	
	end

	def test_amount
		# Zero is not a possibility
		assert_raise RuntimeError do
			CSP::Channel.new 0, 1
		end
		
		c = CSP::Channel.new :one, :one
		l = CSP::ProcessList.new
		l.add(CSP::Process.new {|c| }, c.input)
		
		# We can not give this channel to more than one
		assert_raise RuntimeError do
			l.add(CSP::Process.new {|c| }, c.input)
		end
		
		c = CSP::Channel.new 2, :one
		l = CSP::ProcessList.new
		l.add(CSP::Process.new {|c| }, c.input)
		l.add(CSP::Process.new {|c| }, c.input)
				
		# We can not give this channel to more than two
		assert_raise RuntimeError do
			l.add(CSP::Process.new {|c| }, c.input)
		end
	end

end

