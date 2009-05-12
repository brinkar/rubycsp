require "csp"
require "socket"

CSP::Process.define :server do |control|
	start = control.read
	if start == :start
		puts "Started..."
		alt = CSP::Alternation.new do |l|
			l.read control
			l.skip
		end
		tcp = TCPServer.new("127.0.0.1", 6240)
		loop do
			control_message = alt.execute
			if control_message == :stop
				break
			else
				socket = nil
				CSP::Process.schedule { socket = tcp.accept }
				puts "Connection established..."
				loop do
					msg = nil
					CSP::Process.schedule { msg = socket.recv(255) }
					if msg.strip == "close"
						puts "Closing connection..."
						socket.close
						break
					end
					puts msg
				end
			end
		end
		puts "Stopped!"
	end
end

dist = CSP::Process.define do |control|
	puts "Starting in 3 seconds..."
	CSP::Process.schedule { sleep 3 }
	control.write :start
end

control = CSP::Channel.new


CSP::in_parallel do |map|
	map.add :server, control.output
	map.add dist, control.input
end
