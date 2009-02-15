require "csp"
require "standard_processes"

N = 5000
N_iterations = 10
times = []

consumer = CSP::Process.new do |cin|
	cin.read
	
	t1 = Time.now
	N.times {	cin.read }
	t2 = Time.now
	
	dt = t2-t1
	t_chan = dt / (4*N)
	times << t_chan
	puts "Time: #{dt} s", "Time pr. channel: #{(t_chan*1e6).round(3)} ms (#{t_chan} s)"
	puts "Consumer done, poisoning channel"
	cin.poison
end

N_iterations.times do |i|
	puts "\n------------"
	puts "Iteration #{i}"
	puts "------------"
	
	a = CSP::Channel.new :one, :one
	b = CSP::Channel.new :one, :one
	c = CSP::Channel.new :one, :one
	d = CSP::Channel.new :one, :one
	
	puts "Running commstime test"
	
	CSP::in_parallel do |list|
		list.add CSP::Process.get(:prefix), c.input, a.output, 0
		list.add CSP::Process.get(:delta2), a.input, b.output, d.output
		list.add CSP::Process.get(:successor), b.input, c.output
		list.add consumer, d.input
	end
end

average = (times.inject(0){|sum,e|sum+e}/N_iterations*1e6).round(3)
puts "\n-----------", "Average channel time: #{average}\n"

