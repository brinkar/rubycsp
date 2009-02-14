require "csp"
require "standard_processes"

consumer = CSP::Process.new do |input, output|
	5.times do |i|
		puts "Receiving #{input.read}"
		puts "Sending #{i}"
		output.write i
	end
	output.poison
end

channel1 = CSP::Channel.new
channel2 = CSP::Channel.new

CSP::in_parallel do |list|
	list.add consumer, channel1, channel2
	list.add CSP::Process.get(:prefix), channel2, channel1, 5
end
