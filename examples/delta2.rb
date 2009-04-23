require "csp"
require "processes/standard"

consumer = CSP::Process.define do |output, input1, input2|
	5.times do |i|
		puts "Sending #{i}"
		output.write i
		puts "Receiving #{input1.read} and #{input2.read}"
	end
	output.poison
end

channel1 = CSP::Channel.new :one, :one
channel2 = CSP::Channel.new :one, :one
channel3 = CSP::Channel.new :one, :one

CSP::in_parallel do |map|
	map.add consumer, channel1.input, channel2.output, channel3.output
	map.add :delta2, channel1.output, channel2.input, channel3.input
end
