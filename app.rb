require 'sinatra'
require 'json'
require 'socket'
require 'masscan/command'
require 'masscan/output_file'

class CameraApp < Sinatra::Base
    $ip_cameras = []
    $stream_commands = []
    RES = File.expand_path('/tmp/masscan_results.txt')
    ip_range = -> { Socket.ip_address_list.find(&:ipv4_private?).ip_address.sub(/(\d+)$/, '0') + '/24' }
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

    get '/' do
        erb :index
    end

    post '/scan' do
        $ip_cameras = find_cameras(ip_range.call)
        $ip_cameras.to_json
    end

    post '/add_camera' do
        rtsp_url = params[:url]
        username = params[:username]
        password = params[:password]
        $stream_commands << "ffmpeg -rtsp_transport tcp -i \"#{rtsp_url}\" -filter_complex \"color=black:s=640x360\" -f nut -"
        { status: 'success' }.to_json
    end

    get '/stream' do
        stream :keep_alive do |out|
            out << "run stream...\n"
            Thread.new do
                command = $stream_commands.join(" & ")
                system(command)
            end
            out << "stop streaming...\n"
        end
    end
end

CameraApp.run!
