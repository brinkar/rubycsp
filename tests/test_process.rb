require 'test/unit'
require "csp"

class ChannelTestCase < Test::Unit::TestCase

	def test_return_values
		p1 = CSP::Process.new { "Hello" }
		assert p1.run == "Hello"
		
		p2 = CSP::Process.new { "World" }
		plist = CSP::ProcessList.new
		plist.add p1
		plist.add p2
		assert plist.run == ["Hello", "World"]
		assert plist.run :parallel == ["Hello", "World"]
		assert plist.run :sequential == ["Hello", "World"]
		
		retvals = CSP::in_parallel do |list|
			list.add p1
			list.add p2
		end
		assert retvals == ["Hello", "World"]
		
		retvals = CSP::in_sequence do |list|
			list.add p1
			list.add p2
		end
		assert retvals == ["Hello", "World"]
	end

end

