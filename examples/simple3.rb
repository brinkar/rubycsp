require "csp"

p1 = CSP::Process.new do |input|
	10.times do
			puts "Receiving #{input.read}"
	end
end

p2 = CSP::Process.new do |output, message|
	10.times do |i|
		puts "Sending #{i}"
		output.write i
	end
	message.write "Woot! Was that 10 already?"
end

printer = CSP::Process.new do |message|
	puts message.read
end

c = CSP::Channel.new :one, :one
c2 = CSP::Channel.new :one, :one

CSP::in_parallel do |list|
	list.add p1, c.input
	list.add p2, c.output, c2.output
	list.add printer, c2.input
end
