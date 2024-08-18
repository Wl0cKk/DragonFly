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
        request.body.rewind
        data = JSON.parse(request.body.read)
        vault = './src/camera.json'
        json = JSON.parse(File.read(vault))
        new_id = json.keys.size + 1
        device = data['url']
        json["Camera#{new_id}"] = {
            "ip"         => device.match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)[1],
            "username"   => data['username'],
            "password"   => data['password'],
            "url"        => device,
        }
        File.write(vault, JSON.pretty_generate(json))
        status 200
    end

    get '/stream' do
        
    end

    get '/camera_show_list' do
        content_type :json
        json = JSON.parse(File.read('./src/camera.json'))
        camera_list = json.map { |ind, cam|
            {
                name: ind,
                ip: cam['ip'],
                username: cam['username'],
                password: cam['password'],
                url: cam['url']
            }
        }
        camera_list.to_json
    end

end

CameraApp.run!
