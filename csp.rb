require "thread"

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
		
		class << self
			attr_accessor :processes		
		end
		@processes = []
		
		def initialize(id = nil, &block)
			# TODO: Should also take a method symbol
			raise "No block given to Process" if not block_given?
			@block = block
			if not id.nil?
				raise "Process id must be a Symbol" if not id.is_a?(Symbol)
				@id = id
				# Save the process in a class-wide variable
				self.class.processes << self if self.class.get(id).nil?
			end
		end
		
		def self.get(id)
			raise "Process id must be a Symbol" if not id.is_a? Symbol
			list = @processes.select do |process|
				process.id == id
			end
			# Returning the first match... there shouldn't be more than one.
			return list.first
		end
		
		def self.list
			@processes
		end
		
		def run(args = [])
			# TODO: Handle return values
			begin 
				@block.call(*args)
			rescue ChannelPoison
				args.each do |arg|
					arg.poison if arg.is_a?(Channel) and not arg.poisoned?
				end
				puts "#{@id}: Dying from poisoning..."
			end
		end
	
	end
	
	class ProcessList
		
		include Enumerable
	
		def initialize
			@processes = []
		end
			
		def run(method)
			# TODO: Handle return values
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
		# FIXME: Just an any2any channel for now
		# TODO: Make sure processes get the right end of the channel
		# TODO: What about guards?
		
		def initialize
			@mutex = Mutex.new
			@condition_variable = ConditionVariable.new
			@data = nil
			@pending = false
			@poisoned = false
		end
	
		def write(data)
			raise ChannelPoison if @poisoned
			@mutex.synchronize do
				@data = data
				if @pending
					@pending = false
					@condition_variable.signal
				else
					@pending = true
				end
				@condition_variable.wait(@mutex)
			end
		end
		
		def read
			raise ChannelPoison if @poisoned
			data = nil
			@mutex.synchronize do
				if @pending
					@pending = false
				else
					@pending = true
					@condition_variable.wait(@mutex)
				end
				data = @data # Get it before it changes
				@condition_variable.signal
				data
			end
		end
		
		def poison
			@mutex.synchronize do
				@poisoned = true
				@condition_variable.broadcast
			end
		end
		
		def poisoned?
			@poisoned
		end
	
	end
	
	# TODO: Alternate class (Choice?)
	
	class ChannelPoison < Exception; end

end
