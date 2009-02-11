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
		
		def run(args)
			@block.call(args)
		end
	
	end
	
	class ProcessList
	
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
	
		def process(process, *args)
			@processes << {:process => process, :args => args}
		end
		
	end

	class Channel
		# FIXME: Just the one-2-one channel for now
		# TODO: Make sure processes get the right end of the channel
		# TODO: Poisoning
		
		def initialize
			@mutex = Mutex.new
			@condition = ConditionVariable.new
			@data = nil
			@data_available = false
		end
		
		def write(data)
			@mutex.synchronize do
				@condition.wait(@mutex) if @data_available
				@data = data
				@data_available = true
				@condition.signal
			end
			return data
		end
		
		def read
			data = nil
			@mutex.synchronize do
				@condition.wait(@mutex) if not @data_available
				@data_available = false
				data = @data # Get it before it changes
				@condition.signal
			end
			return data
		end
			
	end
	
	# TODO: Alternate class

end
