require 'test/unit'
require "csp"

class ChannelTestCase < Test::Unit::TestCase

	def test_end_type
		c = CSP::Channel.new

		i = c.input
		assert i.is_a?(CSP::Channel::InputEnd)
		puts i.type
		assert i.type == :input
		
		o = c.output
		assert o.is_a?(CSP::Channel::OutputEnd)
		puts o.type
		assert o.type == :output
	end
	

	def test_read_write
	
		writer = CSP::Process.new do |c|
			c.write "Hello" 
		end
		
		reader = CSP::Process.new do |c|
			c.read
		end
		
		c = CSP::Channel.new

		res = CSP::in_parallel do |map|
			map.add writer, c.input
			map.add reader, c.output
		end
		
		assert res == ["Hello", "Hello"]

		writer = CSP::Process.new do |c|
			c << "Hello" 
		end
		
		res = CSP::in_parallel do |map|
			map.add writer, c.input
			map.add reader, c.output
		end
		
		assert res == ["Hello", "Hello"]
	
	end
=begin
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
=end
end

