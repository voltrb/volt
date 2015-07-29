# The server tracker uses the database to keep a list of all active servers (or
# console, runners, etc...).  When an server instance starts, it registers with
# the database, then reads the list of all other active servers.

require 'socket'

module Volt
  module MessageBus
    class ServerTracker
      UPDATE_INTERVAL = 10
      def initialize(volt_app, server_id, port)
        @volt_app = volt_app
        @server_id = server_id
        @port = port

        @main_thread = Thread.new do
          # Continually update the database letting the server know the server
          # is active.
          loop do
            begin
              register
            rescue Exception => e
              puts "MessageBus Register Error: #{e.inspect}"
            end
            sleep UPDATE_INTERVAL
          end
        end
      end

      def stop
        @main_thread.kill
      end

      # Register this server as active with the database
      def register
        instances = @volt_app.store.active_volt_instances
        instances.where(server_id: @server_id).first.then do |item|
          ips = local_ips.join(',')
          time = Time.now.to_i
          if item
            item.assign_attributes(ips: ips, time: time, port: @port)
          else
            instances << {server_id: @server_id, ips: ips, port: @port, time: time}
          end
        end
      end

      def local_ips
        addr_infos = Socket.ip_address_list

        ips = addr_infos.select do |addr|
          addr.pfamily == Socket::PF_INET
        end.map(&:ip_address)
      end
    end
  end
end