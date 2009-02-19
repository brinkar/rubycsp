require 'test/unit'
require "csp"

class ChannelTestCase < Test::Unit::TestCase

	def test_amount
		assert_raise RuntimeError do
			CSP::Channel.new 0, 1
		end
		c = CSP::Channel.new :one, :one
		l = CSP::ProcessList.new
		l.add(CSP::Process.new {|c| }, c.input)
		assert_raise RuntimeError do
			l.add(CSP::Process.new {|c| }, c.input)
		end
	end

end

