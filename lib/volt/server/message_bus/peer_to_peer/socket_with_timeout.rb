# Connect to a socket using the raw timeout, which responds better than the
# builtin Timeout.

require 'socket'

module Volt
  class SocketWithTimeout
    def self.new(host, port, timeout=nil)
      if RUBY_PLATFORM == 'java'
        TCPSocket.new(host, port)
      else
        addr = Socket.getaddrinfo(host, nil)
        sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

        if timeout
          secs = Integer(timeout)
          usecs = Integer((timeout - secs) * 1_000_000)
          optval = [secs, usecs].pack("l_2")
          sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
          sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
        end
        sock.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
        sock
      end
    end
  end
end