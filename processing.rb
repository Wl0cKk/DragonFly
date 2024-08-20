require 'json'
module Processing
	@dir_path = File.expand_path('./live/stream')
	@stream_file = 'mystream.m3u8'
	@base = File.expand_path('./src/camera.json')
	@cameras = {
		1  => { layout: '1x1', points: '0_0' },
		2  => { layout: '1x2', points: '0_0|0_360' },
		3  => { layout: '3x1', points: '0_0|640_0|1280_0' },
		4  => { layout: '2x2', points: '0_0|640_0|0_360|640_360' },
		6  => { layout: '2x3', points: '0_0|640_0|1280_0|0_360|640_360|1280_360' },
		9  => { layout: '3x3', points: '0_0|640_0|1280_0|0_360|640_360|1280_360|0_720|640_720|1280_720' },
		16 => { layout: '4x4', points: '0_0|640_0|1280_0|1920_0|0_360|640_360|1280_360|1920_360|0_720|640_720|1280_720|1920_720|0_1080|640_1080|1280_1080|1920_1080' }
	} # you could add on, but I didn't

	def self.clean()
		if Dir.exist?(@dir_path) && !Dir.empty?(@dir_path)
			FileUtils.rm_rf Dir.glob("#{@dir_path}/*")
		end
	end

	def self.ready?
		return File.exist?(@dir_path + @stream_file)
	end
	
	def self.calculate_black_squares(camera_count)
		keys = @cameras.keys.sort
		next_key = keys.find { |key| key >= camera_count }
		next_key ? (next_key - camera_count) : 0
	end

	def self.calculate_black_squares(camera_count)
		next_key = @cameras.keys.find { |key| key >= camera_count }
		return [next_key, next_key ? (next_key - camera_count) : 0]
	end

	def self.draft
		script = "#!/bin/bash\n\n"
		cam = JSON.parse(File.read(@base))
		cam_ind = []

		cam.each_with_index do |(key, details), i|
			url = details['url']
			scripted_url = url.sub('rtsp://', "rtsp://#{details['username']}:#{details['password']}@")
			ind = "CAM_#{i+1}" 
			cam_ind << ind
			script += "#{ind}=\"#{scripted_url}\"\n"
		end

		script += "\nAUDIO_OPTS=\"-c:a aac -b:a 160000 -ac 2\"\n"
		script += "VIDEO_OPTS=\"-c:v libx264 -preset ultrafast -b:v 500k\"\n"
		script += "OUTPUT_HLS=\"-hls_time 5 -hls_list_size 5 -start_number 1 -hls_delete_threshold 5 -hls_flags delete_segments\"\n"
		script += "ffmpeg \\\n\s\s-use_wallclock_as_timestamps 1 \\\n"

		cam_ind.each { |ind| script += "\s\s-rtsp_transport tcp -buffer_size 1M -i \"$#{ind}\" \\\n" }

		script += "\s\s-filter_complex \"\\\n"
		pos_cam = []
		pos_black = []
		cam_count = cam_ind.length


		cam_ind.each_with_index { |ind, i| 
			pos_cam << "[a#{i}]"
			script += "\t[#{i}:v] setpts=PTS-STARTPTS, scale=640x360 #{pos_cam[i]}; \\\n"
		}

		calc = calculate_black_squares(cam_count)
		black_squares = calc[1]
		(1..black_squares).each { |i| pos_black << "[b#{i}]" }

		pos_black.each { |pos| script += "\tcolor=black:s=640x360 #{pos}; \\\n" }

		key = calc[0]
		script += "\t#{pos_cam.join()}#{pos_black.join()}\sxstack=inputs=#{cam_count + black_squares}:layout=#{@cameras[key][:points]}, \\\n"
		script += "\tnullsrc=size=1920x1080 [background]; \\\n"
		script += "\t[background][stacked] overlay=0:0 [out]\" \\\n"
		
		script += "\s\s-map \"[out]\" -y $VIDEO_OPTS $OUTPUT_HLS live/stream/mystream.m3u8\n"
		return script
	end
end

