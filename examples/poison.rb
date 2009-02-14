require "csp"

reader_process = CSP::Process.new do |input|
	while msg = input.read
		puts "Receiving #{msg}"
	end
end

writer_process = CSP::Process.new do |output|
	10.times do |i|
		puts "Sending #{i}"
		output.write i
	end
	output.poison
end

channel = CSP::Channel.new

CSP::in_parallel do |list|
	list.add reader_process, channel
	list.add writer_process, channel
end
