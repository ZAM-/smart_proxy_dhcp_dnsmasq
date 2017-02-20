require 'fileutils'
require 'tempfile'

module Proxy::DHCP::Dnsmasq
  class Record < ::Proxy::DHCP::Server
    attr_reader :config_file, :reload_cmd

    def initialize(config_file, reload_cmd, subnet_service)
      @config_file = config_file
      @reload_cmd = reload_cmd

      super('localhost', nil, subnet_service)
    end

    def add_record(options={})
      record = super(options)

      open(@config_file, 'a') do |file|
        file.puts "dhcp-host=#{record.mac},#{record.ip},#{record.name}"
      end
      raise Proxy::DHCP::Error, 'Failed to reload configuration' unless system(@reload_cmd)

      record
    end

    def del_record(record)
      found = false
      tmp = Tempfile.open('reservations') do |output|
        open(@config_file, 'r').each_line do |line|
          output.puts line unless line.start_with? "dhcp-host=#{record.mac}"
          found = true if line.start_with? "dhcp-host=#{record.mac}"
        end
      end
      FileUtils.mv(tmp, @config_file) if found

      raise Proxy::DHCP::Error, 'Failed to reload configuration' unless system(@reload_cmd)

      record
    ensure
      tmp.unlink if tmp
    end
  end
end
