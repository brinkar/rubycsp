require "csp"
require "processes/standard"

N = 5000
N_iterations = 10
times = []

consumer = CSP::Process.define do |cin|
	cin.read
	
	t1 = Time.now
	N.times { cin.read }
	t2 = Time.now
	
	dt = t2-t1
	t_chan = dt / (4*N)
	times << t_chan
	puts "Time: #{dt} s", "Time pr. channel: #{(t_chan*1e6).round(3)} mus (#{t_chan} s)"
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
	
	CSP::in_parallel do |map|
		map.add :prefix, c.output, a.input, 0
		map.add :delta2, a.output, b.input, d.input
		map.add :successor, b.output, c.input
		map.add consumer, d.output
	end
end

average = (times.inject(0){|sum,e|sum+e}/N_iterations*1e6).round(3)
puts "\n-----------", "Average channel time: #{average} mus\n"

