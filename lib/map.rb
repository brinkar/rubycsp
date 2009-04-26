module CSP

	
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
