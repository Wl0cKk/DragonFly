require 'sinatra'
require 'json'
require 'socket'
require 'masscan/command'
require 'masscan/output_file'
require_relative 'processing.rb'

class CameraApp < Sinatra::Base
	set :bind, '0.0.0.0'
	set :port, 1234

	set :streaming, false
	set :ffmpeg_process, nil

	RES = File.expand_path('/tmp/masscan_results.txt')
	CAM_LIST_PATH = './src/camera.json'

	def initialize
		super
		@ip_cameras = []
		@stream_commands = []
	end

	def ip_range(); Socket.ip_address_list.find(&:ipv4_private?).ip_address.sub(/(\d+)$/, '0') + '/24' end

	def load_cameras(); JSON.parse(File.read(CAM_LIST_PATH)) end

	def save_cameras(cameras); File.write(CAM_LIST_PATH, JSON.pretty_generate(cameras))	end

	def update_camera_data(camera_id, data)
		json = load_cameras
		json[camera_id] = {
			"ip" => data['url'].match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)[1],
			"username" => data['username'],
			"password" => data['password'],
			"url" => data['url']
		}
		return save_cameras(json)
	end

	def find_cameras(ip)
		Masscan::Command.sudo do |ms|
			ms.output_format = :list
			ms.output_file = RES
			ms.ips = ip
			ms.ports = [554]
		end

		rtsp_devices = []
		output_file = Masscan::OutputFile.new(RES, format: :list)
		output_file.each { |rec| rtsp_devices << rec['ip'].to_s }
		return rtsp_devices.sort!
	end

	def stop_stream!
	    if settings.streaming && settings.ffmpeg_process
	        Process.kill('TERM', settings.ffmpeg_process)
	        Process.wait(settings.ffmpeg_process)
	        settings.streaming = false
	        settings.ffmpeg_process = nil
	    end
	end

	get '/' do
		erb :index
	end

	post '/scan' do
		@ip_cameras = find_cameras(ip_range)
		@ip_cameras.to_json
	end

	post '/add_camera' do
		request.body.rewind
		data = JSON.parse(request.body.read)
		json = load_cameras

		existing_camera_id = json.find { |_, cam| cam['url'] == data['url'] }

		if existing_camera_id
			camera_id = existing_camera_id.first
			update_camera_data(camera_id, data)
			status 200
			return { message: "#{camera_id} updated successfully." }.to_json
		else
			new_id = "Camera#{json.size + 1}"
			update_camera_data(new_id, data)
			status 201
			return { message: "Added successfully!" }.to_json
		end
	end

	get '/camera_show_list' do
		content_type :json
		load_cameras.map { |name, cam| cam.merge({"name" => name}) }.to_json
	end

	delete '/delete_camera/:cameraId' do |cam_id|
		json = load_cameras
		json.delete(cam_id)

		updated_cameras = json.each_with_index.to_h { |(_, val), i| ["Camera#{i+1}", val] }
		save_cameras(updated_cameras)
		status 204
	end

	patch '/update_camera/:cameraId' do |cam_id|
		request.body.rewind
		data = JSON.parse(request.body.read)
		update_camera_data(cam_id, data)
		status 200
		return { message: "#{cam_id} updated successfully." }.to_json
	end

	post '/stop_stream' do
		stop_stream_if_running
		status 200
	end

	post '/start_stream' do
		stop_stream!
		Processing.clean
		script = Processing.draft
		File.write('/tmp/stream.sh', script)
		settings.ffmpeg_process = Process.spawn("bash /tmp/stream.sh", chdir: "#{Dir.pwd}")
		settings.streaming = true
		status 200
	end

	get '/stream' do
	    erb :live_camera
	end

	get '/mystream.m3u8' do
	    send_file File.join(settings.root, 'live/stream/mystream.m3u8')
	end

	get '/:segment' do
		send_file File.join(settings.root, "/live/stream/#{params[:segment]}")
	end

	post '/kill' do
		stop_stream!
		Process.kill("TERM", Process.pid)
	end
end

CameraApp.run!
