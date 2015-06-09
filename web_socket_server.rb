require 'socket'
require './web_socket_connection'
require 'digest/sha1'
require 'base64'

class WebSocketServer
  WS_MAGIC_STRING = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  def initialize(options = {path: '/', port: 4567, host: 'localhost'})
    @path, port, host = options[:path], options[:port], options[:host]
    @tcp_server = TCPServer.new(host, port)
  end

  def accept
    socket = @tcp_server.accept
    send_handshake(socket) && WebSocketConnection.new(socket)
  end

  private
  def send_handshake(socket)
    request_line = socket.gets
    header = get_header(socket)
    puts header
    if valid?(request_line, header)
      send_accept_resp(socket, header)
      return true
    else
      send_400(socket)
      return false
    end
  end

  def symbolize(key)
    key.downcase.delete(':').gsub('-', '_').to_sym
  end

  def parse_header(line)
    header = /^[\w\-]+:/.match(line)
    return_header = {}
    return {} if header.nil?
    key = symbolize(header[0])
    value = line[(header.offset(0).last + 1)..-1]
    return_header[key] = value.strip
    return_header
  end

  def get_header(conn)
    headers = {}
    while line = conn.gets
      break if line == "\r\n"
      headers.merge!(parse_header(line))
    end

    headers
  end

  def send_400(conn)
    conn << "HTTP/1.1 400 Bad Request\r\n" +
      "Content-Type: text/plain\r\n" +
      "Connection: close\r\n" +
      "\r\n" +
      "Incorrect request"
    conn.close
  end

  def valid?(request_line, header)
    (request_line =~ /GET #{@path} HTTP\/1.1/) && header[:sec_websocket_key]
  end

  def accept_code(key)
    digest = Digest::SHA1.digest(key + WS_MAGIC_STRING)
    Base64.encode64(digest)
  end

  def send_accept_resp(conn, header)
    ws_accept = accept_code(header[:sec_websocket_key])
    conn << "HTTP/1.1 101 Switching Protocols\r\n" + 
      "Upgrade: websocket\r\n"  +
      "Connection: Upgrade\r\n" +
      "Sec-WebSocket-Accept: #{ws_accept}\r\n"
  end
end
