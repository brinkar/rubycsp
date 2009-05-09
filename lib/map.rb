require "thread"

module CSP
	
	class Map
		
		def initialize
			@processes = []
			@process_queue = Queue.new
		end
		
		def add(definition, *args)
			p = CSP::Process.new definition, *args
			@processes << p
			p.map = self
		end
		
		def <<(process, *args)
			add(process, *args)
		end
		
		def run
			@processes.each do |p|
				@process_queue << p
			end

			loop do
				# Take processes from the queue if not empty
				break if finished?				
				p = @process_queue.shift
				ret = p.run
				if ret == :enqueue
					enqueue p
				elsif ret.is_a? Numeric
					Thread.new do
						sleep ret
						@process_queue << p
					end
				end
			end

			puts "#{@processes.size} processes finished."
						
			values = @processes.map do |p|
				p.value
			end
			values
		end
		
		def finished?
			@processes.all? do |p|
				p.finished?
			end
		end
		
		def enqueue(process)
			if @processes.include?(process)
				@process_queue << process
			else
				raise "Cannot enqueue unknown process."
			end
		end
			
		class Deadlock < Exception
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
	
end
