require "csp"
require "processes/standard"

consumer = CSP::Process.define do |input, output|
	5.times do |i|
		puts "Sending #{i}"
		output.write i
		puts "Receiving #{input.read}"
	end
	output.poison
end

channel1 = CSP::Channel.new :one, :one
channel2 = CSP::Channel.new :one, :one

CSP::in_parallel do |map|
	map.add consumer, channel1.output, channel2.input
	map.add :successor, channel2.output, channel1.input
end
