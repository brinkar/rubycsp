require 'test/unit'
require "csp"

class AlternationTestCase < Test::Unit::TestCase

	def test_read_alternation

		test = CSP::Process.define do |cin1, cin2|

			alt = CSP::Alternation.new do |list|
				list.read cin1
				list.read cin2
			end
			
			alt.execute
		end
		
		cons1 = CSP::Process.define do |cout1|
			cout1 << "Hello"
		end
		
		c1 = CSP::Channel.new
		c2 = CSP::Channel.new
		
		res = CSP::in_parallel do |map|
			map.add test, c1.output, c2.output
			map.add cons1, c1.input
		end
		
		assert res == ["Hello", "Hello"]
		
		cons2 = CSP::Process.define do |cout2|
			cout2 << "Hello"
			"CSP"
		end

		res = CSP::in_parallel do |map|
			map.add test, c1.output, c2.output
			map.add cons2, c2.input
		end
		
		assert res == ["Hello", "CSP"]
		
	end
	
	def test_write_alternation
			
		test = CSP::Process.define do |cout1, cout2|

			alt = CSP::Alternation.new do |list|
				list.write cout1, "Hello"
				list.write cout2, "CSP"
			end
			
			alt.execute
		end
		
		cons1 = CSP::Process.define do |cin1|
			cin1.read
		end
		
		c1 = CSP::Channel.new
		c2 = CSP::Channel.new
		
		res = CSP::in_parallel do |map|
			map.add test, c1.input, c2.input
			map.add cons1, c1.output
		end
		
		assert res == ["Hello", "Hello"]
		
		cons2 = CSP::Process.define do |cin2|
			cin2.read
		end

		res = CSP::in_parallel do |map|
			map.add test, c1.input, c2.input
			map.add cons2, c2.output
		end
		
		assert res == ["CSP", "CSP"]
	
	end
	
	def test_mix_alternation

		test = CSP::Process.define do |cout1, cin2|

			alt = CSP::Alternation.new do |list|
				list.write cout1, "Hello"
				list.read cin2
			end
			
			alt.execute
		end
		
		cons1 = CSP::Process.define do |cin1|
			cin1.read
		end
		
		c1 = CSP::Channel.new
		c2 = CSP::Channel.new
		
		res = CSP::in_parallel do |map|
			map.add test, c1.input, c2.output
			map.add cons1, c1.output
		end
		
		assert res == ["Hello", "Hello"]
		
		cons2 = CSP::Process.define do |cout2|
			cout2.write "CSP"
		end

		res = CSP::in_parallel do |map|
			map.add test, c1.input, c2.output
			map.add cons2, c2.input
		end
		
		assert res == ["CSP", "CSP"]
	
	end
	
	def test_select
		# TODO
	end

	def test_hook
		# TODO
	end
	
	def test_skip
		# TODO
	end
	
	def test_timeout
		# TODO
	end

end
