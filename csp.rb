module CSP

	class Process < Fiber

		private :resume
		attr_accessor :name
		
		def initialize(name = "Noname process", &body)
			# TODO: Check for valid args
			@name = name
			super(&body)
			@setup = false
			@ends = []
		end
		
		def setup(*args)
			args.each do |arg|
				arg.process = self if arg.is_a?(Channel::End)
				@ends << arg
			end
			val = resume *args
			@setup = true
			val
		end
		
		def run
			raise "Process must be setup." if not @setup
			begin
				res = resume
			rescue Channel::Poison
				puts "'#{@name}' dying from poisoning!"
			end
			return res
		end
		
		def ends(type = nil)
			raise "Process must be setup" if not @setup
			if type.nil?
				return @ends
			else
				return @ends.select { |e| e.type == type }
			end
		end
		
	end
	
	def CSP::in_parallel(&block)
		values = nil
		if block_given?
			map = Map.new
			yield map
			values = map.run
		else
			raise "No block given to 'in_parallel'"
		end
		return values
	end
	
	class Map
		
		def initialize
			@processes = []
		end
		
		def add(process, *args)
			@processes << {:process => process, :args => args}
		end
		
		def <<(process, *args)
			add(process, &args)
		end
		
		def run
			@processes.each do |p|
				p[:value] = p[:process].setup *p[:args]
			end

			dead = 0
			while dead < @processes.size
				begin
					@processes.each do |p|
						p[:value] = p[:process].run
					end
				rescue FiberError
					dead += 1
				end					
			end

			puts "All processes finished."

			values = @processes.map do |p|
				p[:value]
			end
			values
		end
	
	end
	
	class Channel
		
		def initialize(from = :any, to = :any, buffer = 1)
			@from = amount_to_number from
			@to = amount_to_number to
			@buffer = buffer
			@data = []
			@input_ends = []
			@output_ends = []
			@poisoned = false
		end
	
		def write(obj)
			raise Poison if @poisoned
			while @data.size == @buffer
				Fiber.yield
			end
			@data << obj
			return obj
		end
		
		def read
			raise Poison if @poisoned
			while @data.empty?
				Fiber.yield
			end
			@data.shift	
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
				@channel.read
			end
			
		end
		
		class InputEnd < End

			def write(data)
				@channel.write data
			end
			
			def <<(data)
				write(data)
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
