
require "thread"

module CSP

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
