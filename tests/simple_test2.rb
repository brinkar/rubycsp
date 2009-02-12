require "csp"

p1 = CSP::Process.new do |input|
	10.times do
			puts "Receiving #{input.read}"
	end
end

p2 = CSP::Process.new do |output|
	10.times do |i|
		puts "Sending #{i}"
		output.write "#{i}"
	end
end

plist = CSP::ProcessList.new
c2 = CSP::Channel.new

plist.add(CSP::Process.new do |printer|
	c = CSP::Channel.new

	CSP::in_parallel do |list|
		list.add p1, c
		list.add p2, c
	end
	
	printer.write "We say goodbye!"
end, c2)

plist.add(CSP::Process.new do |message|
	puts message.read
end, c2)

plist.run :parallel
