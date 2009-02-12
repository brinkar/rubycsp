require "csp"

reader_process = CSP::Process.new do |input|
	10.times do
			puts "Receiving #{input.read}"
	end
end

writer_process = CSP::Process.new do |output|
	10.times do |i|
		puts "Sending #{i}"
		output.write i
	end
end

channel = CSP::Channel.new

CSP::in_parallel do |list|
	list.add reader_process, channel
	list.add writer_process, channel
end

puts "Making sure the order doesn't matter"

CSP::in_parallel do |list|
	list.add writer_process, channel
	list.add reader_process, channel
end
