require "thread"
require "monitor"

module CSP

	def CSP::in_parallel(&block)
		if block_given?
			p = ProcessList.new
			yield p
			p.run :parallel
		else
			raise "No block given to 'in_parallel'"
		end
	end
	
	def CSP::in_sequence(&block)
		if block_given?
			p = ProcessList.new
			yield p
			p.run :sequential
		else
			raise "No block given to 'in_sequence'"
		end
	end

	class Process
		
		attr_reader :id
		
		def initialize(id = nil, &block)
			if id.nil? or id.is_a?(String) or id.is_a?(Symbol)
				@id = id
			else
				raise "Process id must be String or Symbol"
			end
			if block_given?
				@block = block
			else
				# TODO: Should also take a method symbol
				raise "No block given to Process"
			end
		end
		
		def run(args = nil)
			@block.call(*args)
		end
	
	end
	
	class ProcessList
		
		include Enumerable
	
		def initialize
			@processes = []
		end
			
		def run(method)
			case method
			when :parallel
				threads = []
				@processes.each do |p|
					threads << Thread.new { p[:process].run(p[:args]) }
				end
				threads.each do |t|
					t.join
				end
			when :sequential
				@processes.each do |p|
					p[:process].run p[:args]
				end
			end
		end
	
		def each(&block)
			@processes.each block
		end
		
		def add(process, *args)
			@processes << {:process => process, :args => args}
		end
		
	end

	class Channel
		# FIXME: The order in which parallel processes are run shouldn't matter (Guards?)
		# FIXME: Just the one-2-one channel for now
		# TODO: Make sure processes get the right end of the channel
		# TODO: Poisoning
		# FIXME: What's going on in Ruby 1.9?
		
		def initialize
			@mutex = Mutex.new
			@condition_variable = ConditionVariable.new
			@data = nil
			@ready_to_read = false
			@ready_to_write = true
		end
		
		def write(data)
			@mutex.synchronize do
				@condition_variable.wait(@mutex) if not @ready_to_write
				@data = data
				@ready_to_write = false
				@ready_to_read = true
				@condition_variable.signal
			end
			return data
		end
		
		def read
			data = nil
			@mutex.synchronize do
				@condition_variable.wait(@mutex) if not @ready_to_read
				@ready_to_read = false
				@ready_to_write = true
				data = @data # Get it before it changes
				@condition_variable.signal
			end
			return data
		end
	
	end
	
	# TODO: Alternate class (Choice?)

end
