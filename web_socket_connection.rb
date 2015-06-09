require 'socket'

class WebSocketConnection
  attr_reader :socket

  def initialize(socket)
    @socket = socket
  end

  def recv
  end

  def close
    @socket.close
  end
end
