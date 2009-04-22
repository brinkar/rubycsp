
CSP::Process.new :identity do |cin, cout|
	while true
		t = cin.read
		cout.write t
	end	
end

CSP::Process.new :prefix do |cin, cout, prefix_item = 0|
	t = prefix_item
	while true
		cout.write t
		t = cin.read
	end	
end

CSP::Process.new :delta2 do |cin, cout1, cout2|
	while true
		t = cin.read
		cout1.write t
		cout2.write t
	end	
end

CSP::Process.new :successor do |cin, cout|
	while true
		cout.write(cin.read+1)
	end	
end

