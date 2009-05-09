require 'test/unit'
require "csp"

class ChannelTestCase < Test::Unit::TestCase

	def test_create_and_run
	
		pd = CSP::Process.define :test do |n|
			n + 1
		end

		assert_raise RuntimeError do
			CSP::Process.define :test do |n|
				n + 1
			end
		end
		
		p1 = CSP::Process.new pd, 10
				
		assert (not p1.finished?)
		
		assert p1.run == 11
		
		assert p1.finished?
		
		assert_raise CSP::Process::Finished do
			p1.run
		end
		
		p2 = CSP::Process.new :test, 20
		
		assert p2.run == 21
		
		assert p2.finished?		
		
		assert_raise CSP::Process::Finished do
			p2.run
		end
		
	end
	
	def test_remove_and_clear
		
		CSP::Process.clear!
				
		CSP::Process.define :test do |n|
			n + 1
		end
		
		CSP::Process.clear!
				
		assert_nothing_thrown do 
			CSP::Process.define :test do |n|
				n + 1
			end
		end
		
		CSP::Process.remove! :test

		assert_nothing_thrown do 
			CSP::Process.define :test do |n|
				n + 1
			end
		end

	end
	
	def test_list
		
		CSP::Process.clear!
		
		CSP::Process.define :test do |n|
			n + 1
		end
		
		assert CSP::Process.list.size == 1
		assert CSP::Process.definitions.size == 1
		
		assert CSP::Process.list.first.name == :test
		
	end
	
	def test_ends
	
		c = CSP::Channel.new
		pd = CSP::Process.define do |c|
			"Hello"
		end
		p = CSP::Process.new pd, c.input
		
		assert p.run == "Hello"
		assert p.ends.size == 1
		assert p.ends(:input).size == 1
		assert p.ends(:output).size == 0
		
		assert p.ends.first.process == p
	
	end

end

