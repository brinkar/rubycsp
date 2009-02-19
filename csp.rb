
# TODO: Alternative class
# TODO: Guards?

require "thread"

module CSP

	def CSP::in_parallel(&block)
		retvals = nil
		if block_given?
			p = ProcessList.new
			yield p
			retvals = p.run :parallel
		else
			raise "No block given to 'in_parallel'"
		end
		return retvals
	end
	
	def CSP::in_sequence(&block)
		retvals = nil
		if block_given?
			p = ProcessList.new
			yield p
			retvals = p.run :sequential
		else
			raise "No block given to 'in_sequence'"
		end
		return retvals
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
			retval = nil
			begin 
				retval = @block.call(*args)
			rescue Channel::Poison
				args.each do |arg|
					arg.poison if (arg.is_a?(Channel) or arg.is_a?(Channel::End)) and not arg.poisoned?
				end
				puts "#{@id}: Dying from poisoning..."
			end
			return retval
		end
	
	end
	
	class ProcessList
		
		include Enumerable
	
		def initialize
			@processes = []
		end
			
		def run(method = :sequential)
			retvals = []
			case method
			when :parallel
				threads = []
				@processes.each do |p|
					threads << Thread.new do
						retvals[@processes.index(p)] = p[:process].run(p[:args])
					end
				end
				threads.each do |t|
					t.join
				end
			when :sequential
				@processes.each do |p|
					retvals[@processes.index(p)] = p[:process].run p[:args]
				end
			end
			return retvals
		end
	
		def each(&block)
			@processes.each do |p|
				yield p
			end
		end
		
		def add(process, *args)
			@processes << {:process => process, :args => args}
		end
		
	end

	class Channel
		
		def initialize(from = :any, to = :any)
			@from = amount_to_number from
			@to = amount_to_number to
			@mutex = Mutex.new
			@condition_variable = ConditionVariable.new
			@data = nil
			@pending = false
			@poisoned = false
			@input_ends = []
			@output_ends = []
		end
	
		def write(data)
			raise Poison if @poisoned
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
			raise Poison if @poisoned
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
		
		def input
			if @input_ends.size < @from
				input_end = InputEnd.new self
				@input_ends << input_end 
				return input_end
			else
				raise "No more than #{@from} input ends are allowed on this channel."
			end
		end
	
		def output
			if @output_ends.size < @to
				output_end = OutputEnd.new self
				@output_ends << output_end 
				return output_end		
			else
				raise "No more than #{@to} output ends are allowed on this channel."
			end
		end
		
		class End
			
			def initialize(channel)
				@channel = channel
			end
			
			def poison
				@channel.poison
			end
			
			def poisoned?
				@channel.poisoned?
			end
			
		end
		
		class InputEnd < End
		
			def read
				@channel.read
			end				
			
		end
		
		class OutputEnd < End

			def write(data)
				@channel.write data
			end
		
		end
		
		class Poison < Exception; end
		
		private
		
		def amount_to_number(amount)
			unless (amount.is_a?(Fixnum) and amount > 0) or [:one, :any].include?(amount)
				raise "Number of input and output ends must be a positive integer, :one or :any"
			end
			case amount
			when :any
				amount = 1.0/0
			when :one
				amount = 1
			end
			return amount
		end
	
	end

end
