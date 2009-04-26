require "fiber"

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
		attr_reader :fiber
		attr_accessor :pending
				
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
			@pending = false
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
	
	class Alternation
	
		class List
		
			attr_reader :guards
		
			def initialize
				@guards = []	
			end
		
			def write(input_end, val, &block)
				guard = InputGuard.new input_end, val, &block 
				add guard
			end
			
			def read(output_end, &block)
				guard = OutputGuard.new output_end, &block 
				add guard
			end
			
			def add(guard)
				raise(ArgumentError, "Argument must be an Alternation::Guard") unless guard.is_a?(Guard)
				@guards << guard
			end
		
		end
		
		class Guard
		
			def initialize(&block)
				@block = block
			end

			def open?
				raise "Must be implemented!"
			end
			
			def closed?
				not open?
			end
			
			def execute
				result = methods.include?(:on_execute) ?  on_execute : nil
				@block.call self, result if @block
				return result
			end
			
		end
		
		class InputGuard < Guard
		
			def initialize(input_end, val, &block)
				@input_end = input_end
				@val = val
				super(&block)
			end
			
			def open?
				@input_end.writable?
			end
			
			def on_execute
				@input_end.write @val
				@val
			end
		
		end
		
		class OutputGuard < Guard
			
			def initialize(output_end, &block)
				@output_end = output_end
				super(&block)
			end
			
			def open?
				@output_end.readable?
			end
			
			def on_execute
				@output_end.read
			end
		
		end
		
		def initialize(&block)
			@block = block
			@list = List.new
			block.call @list
		end
		
		def execute
			guard = choose
			guard.execute
		end
		
		def select
			guard = choose
			guard
		end
	
		private	
		
		def choose
			while true
				open_guards = @list.guards.select { |guard| guard.open? }
				if open_guards.empty?
					Fiber.yield
				else
					return open_guards.first
				end
			end
		end
	
	end
	
end
