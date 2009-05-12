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
			
			def schedule(&block)
				Fiber.yield block
			end
			
		end

		@definitions = []
		
		attr_reader :value
		attr_reader :fiber
		attr_accessor :pending
		attr_writer :map
		attr_writer :finished
				
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
			@finished = false
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
				raise Finished, "'#{@definition.name}' is finished. Cannot be run."
			end
			@finished = true if not @fiber.alive?
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
		
		def finished?
			@finished
		end
		
		def enqueue
			@map.enqueue self if @map
		end

	end
	
end
