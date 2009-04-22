require 'test/unit'
require "csp"

class MapTestCase < Test::Unit::TestCase

	def test_run

		p1 = CSP::Process.new :reader do |c| 
			10.times do
				c.read
			end
			"hello"
		end

		p2 = CSP::Process.new :writer do |c|
			10.times do |i|
				c.write "Hello #{i}"
			end
			c.poison
			"csp"
		end

		c = CSP::Channel.new

		map = CSP::Map.new

		map.add p1, c.output
		map.add p2, c.input

		assert map.run == ["hello", "csp"]

	end
	
	def test_in_parallel
	
		p1 = CSP::Process.new :reader do |c| 
			10.times do
				c.read
			end
			"hello"
		end

		p2 = CSP::Process.new :writer do |c|
			10.times do |i|
				c.write "Hello #{i}"
			end
			c.poison
			"csp"
		end
	
		c = CSP::Channel.new

		values = CSP::in_parallel do |map|
			map.add p1, c.output
			map.add p2, c.input
		end
		assert values == ["hello", "csp"]
		
	end
	
end
