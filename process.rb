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
				#puts "#{@id}: Dying from poisoning..."
			rescue
				puts $!.message
				puts $!.backtrace
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
	
end
