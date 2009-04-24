module CSP

	class Process
			
		class Definition

			attr_reader :name
			attr_reader :block

			def initialize(name, &block)
				@name = name
				@block = block
			end

		end
		
		class Finished < Exception
		end
	
		class << self
		
			attr_reader :definitions
			
			def define(name = nil, &block)
				pd = Definition.new name, &block
				if not name.nil?
					if @definitions.any? { |pd| pd.name == name }
						raise "A process named '#{name}' is already defined."
					else
						@definitions << pd	
					end
				end
				pd
			end
			
			def get(name)
				@definitions.each do |pd|
					return pd if pd.name == name
				end
				return nil
			end
			
			def list
				@definitions
			end
			
			def clear!
				@definitions = []
			end
			
			def remove!(name)
				@definitions.each do |d|
					@definitions.delete(d) if d.name == name
				end
			end
			
		end

		@definitions = []
		
		attr_reader :value
				
		def initialize(definition, *args)
			if not definition.is_a?(Definition)
				definition = self.class.get definition
				raise "No such process defined." if definition.nil?
			end
			@definition = definition
			@fiber = Fiber.new &definition.block
			@value = nil
			@args = args
			@ends = []
			@args.each do |arg|
				if arg.is_a?(Channel::End)
					arg.process = self
					@ends << arg
				end
			end
		end
		
		def run
			begin
				res = @fiber.resume *@args
			rescue Channel::Poison
				puts "'#{@definition.name}' dying from poisoning!"
				@ends.each do |e|
					e.poison
				end
			rescue FiberError
				raise Finished
			end
			@value = res
			return res
		end
		
		def ends(type = nil)
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
		
		def add(definition, *args)
			p = CSP::Process.new definition, *args
			@processes << p
		end
		
		def <<(process, *args)
			add(process, *args)
		end
		
		def run

			finished = 0
			while finished < @processes.size
				begin
					@processes.each do |p|
						p.run
					end
				rescue CSP::Process::Finished
					finished += 1
				end					
			end

			puts "#{finished} processes finished."

			values = @processes.map do |p|
				p.value
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
