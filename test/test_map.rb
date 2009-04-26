require 'test/unit'
require "csp"

class MapTestCase < Test::Unit::TestCase

	def test_run

		reader = CSP::Process.define do |c| 
			10.times do
				c.read
			end
			"hello"
		end

		writer = CSP::Process.define do |c|
			10.times do |i|
				c.write("Hello #{i}")
			end
			c.poison
			"csp"
		end

		c = CSP::Channel.new

		map = CSP::Map.new

		map.add reader, c.output
		map.add writer, c.input

		assert map.run == ["hello", "csp"]

	end
	
	def test_in_parallel
	
		reader = CSP::Process.define do |c| 
			10.times do
				c.read
			end
			"hello"
		end

		writer = CSP::Process.define do |c|
			10.times do |i|
				c.write "Hello #{i}"
			end
			c.poison
			"csp"
		end
	
		c = CSP::Channel.new

		values = CSP::in_parallel do |map|
			map.add reader, c.output
			map.add writer, c.input
		end
		assert values == ["hello", "csp"]
		
	end
	
	def test_in_sequence
		# TODO
	end
	
	def test_fork
		# TODO
	end
	
end
