STREAM_PWD = File.expand_path('./')
LIVE_FILE = '/mystream.m3u8'

while true
	stream = STREAM_PWD+LIVE_FILE
	
	unless File.exist?(stream)
		sleep(10)
		next
	end 
	
	used_ts = Dir.glob(STREAM_PWD+'/*.ts')
	in_use = Array.new
	
	File.readlines(stream).each { |line|
		in_use << "#{STREAM_PWD}/#{line.chomp}" if line.end_with?(".ts\n")
	}

	used_ts.each { |segment|
		File.delete(segment) unless in_use.include?(segment)
	}
	sleep(10)
end