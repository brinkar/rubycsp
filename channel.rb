module CSP

	class Channel
		
		def initialize(from = :any, to = :any, buffer = 0)
			@from = amount_to_number from
			@to = amount_to_number to
			@buffer = buffer
			@data = []
			@input_ends = []
			@output_ends = []
			@read_queue = []
			@write_queue = []
			@poisoned = false
		end
	
		def write(input_end, obj)
			raise Poison if poisoned?
			raise ArgumentError, "Invalid input end." unless @input_ends.include?(input_end)
			@data << obj
			if @data.size > @buffer
				p = input_end.process
				@write_queue << p
				if @read_queue.empty?
					Fiber.yield while @read_queue.empty?
					@read_queue.shift.fiber.transfer								
				else
					@read_queue.shift.fiber.transfer
				end
			end
			return obj
		end
		
		def read(output_end)
			raise Poison if poisoned?
			raise ArgumentError, "Invalid output end." unless @output_ends.include?(output_end)
			d = @data.size - @write_queue.size
			if d > 0 and d <= @buffer
				data = @data.shift
			else
				p = output_end.process
				@read_queue << p
				if @write_queue.empty?
					Fiber.yield while @write_queue.empty?
					data = @data.shift
					@write_queue.shift.fiber.transfer
				else
					data = @data.shift
					@write_queue.shift.fiber.transfer
				end
			end
			return data
		end
		
		def writable?
			@data.size < @buffer or not @read_queue.empty?
		end
		
		def readable?
			@data.size > @write_queue.size or not @write_queue.empty?
		end
		
		def poison
			@poisoned = true
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
		
			attr_reader :process
			
			def initialize(channel)
				@channel = channel
				@process = nil
			end
			
			def type
				self.class.to_s.split("::").last.split("End").first.downcase.to_sym
			end
			
			def process=(process)
				@process = process if process.is_a?(CSP::Process)
			end
			
			def poison
				@channel.poison
			end
			
			def poisoned?
				@channel.poisoned?
			end
			
		end
		
		class OutputEnd < End
		
			def read
				@channel.read self
			end
			
			def readable?
				@channel.readable?
			end
			
			def active?
				@active
			end
			
		end
		
		class InputEnd < End

			def write(data)
				@channel.write self, data
				data
			end
			
			def <<(data)
				write(data)
			end
			
			def writable?
				@channel.writable?
			end
		
		end
		
		class Poison < Exception; end
		
		private
		
		def amount_to_number(amount)
			amount = :any if amount == nil
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
