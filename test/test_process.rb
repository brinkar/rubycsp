require 'test/unit'
require "csp"

class ChannelTestCase < Test::Unit::TestCase

	def test_setup_and_return
	
		p1 = CSP::Process.new do |n|
			n + 1
		end
		
		assert p1.setup(10) == 11
		
		assert_raise FiberError do
			p1.run
		end
	
		p2 = CSP::Process.new do
			"Hello"
		end

		assert_raise RuntimeError do
			p2.run
		end
		
		assert p2.setup == "Hello"

		assert_raise FiberError do
			p2.run
		end
		
	end
	
	def test_ends
		c = CSP::Channel.new
		p1 = CSP::Process.new do |c|
			"Hello"
		end
		assert p1.setup(c.input) == "Hello"
		assert p1.ends.size == 1
		assert p1.ends(:input).size == 1
		assert p1.ends(:output).size == 0
		
		assert p1.ends.first.process == p1
	end

end

