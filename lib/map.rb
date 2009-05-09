require "monitor"

module CSP
	
	class Map
		
		def initialize
			@processes = []
			@process_queue = []
			@process_queue.extend MonitorMixin
			@queue_condition = @process_queue.new_cond
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
			@process_queue += @processes
			loop do
				# Take processes from the queue if not empty
				if not @process_queue.empty?
					@process_queue.shift.run
				elsif finished?
					break
				else
					raise Deadlock
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
