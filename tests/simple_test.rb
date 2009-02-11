require "csp"

p1 = CSP::Process.new do |input|
	10.times do
			puts "Receiving #{input.first.read}"
	end
end

p2 = CSP::Process.new do |output|
	10.times do |i|
		puts "Sending #{i}"
		output.first.write "#{i}"
	end
end

c = CSP::Channel.new

CSP::in_parallel do |list|
	list.process p1, c
	list.process p2, c
end
