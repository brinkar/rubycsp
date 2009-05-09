module CSP

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
			
			def timeout(time, &block)
				guard = TimeoutGuard.new time, &block 
				add guard
			end
			
			def skip(&block)
				guard = SkipGuard.new &block 
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
		
		class TimeoutGuard < Guard
		
			def initialize(time, &block)
				@start_time = Time.now
				@time = time
				super(&block)
			end
			
			def open?
				Fiber.yield ((@start_time + @time) - Time.now)
				true
			end
			
			def on_execute
				Time.now - @start_time
			end
		
		end
		
		class SkipGuard < Guard
		
			def open?
				true
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
			loop do
				@list.guards.each do |g|
					return g if g.open?
				end
				Fiber.yield :enqueue
			end
		end
	
	end
	
end
