require 'socket'
require 'masscan/command'
require 'masscan/output_file'

RES = File.expand_path('/tmp/masscan_results.txt')
ip_range = -> { Socket.ip_address_list.find(&:ipv4_private?).ip_address.sub(/(\d+)$/, '0') + '/24' }

def find_cameras(ip)
    Masscan::Command.sudo do |ms|
        ms.output_format = :list
        ms.output_file   = RES
        ms.ips   = ip
        ms.ports = [554]
    end
    rtsp_devices = Array.new
    output_file = Masscan::OutputFile.new(RES, format: :list)
    .each { |rec|
        rtsp_devices << rec['ip'].to_s
    }
    return rtsp_devices
end

puts find_cameras(ip_range.call).inspect