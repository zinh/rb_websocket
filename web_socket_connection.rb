require 'socket'
require 'byebug'

class WebSocketConnection
  attr_reader :socket

  def initialize(socket)
    @socket = socket
  end

  def recv
    fin_opcode = socket.read(1).bytes[0]
    mask_payload_len = socket.read(1).bytes[0]
    payload_len = mask_payload_len - 128
    length = case payload_len
             when 126
               socket.read(2).unpack("N")[0]
             when 127
               socket.read(8).unpack("Q>")[0]
             else
               payload_len
             end
    masking_key = socket.read(4).bytes
    payload = socket.read(length).bytes
    message = payload.each_with_index.map do |chunk, index|
      mask = index % 4
      chunk ^ masking_key[mask]
    end
    message.pack("C*")
  end

  def send(msg)
    fin_opcode = 129
    length = msg.bytesize
    mask_payload_len = length
    frame = [fin_opcode, mask_payload_len, msg.bytes]
    socket << frame.flatten.pack("C*")
  end

  def send1(message)
    bytes = [129]
    size = message.bytesize

    bytes +=  if size <= 125
                [size]
              elsif size < 2**16
                [126] + [size].pack("n").bytes
              else
                [127] + [size].pack("Q>").bytes
              end

    bytes += message.bytes
    data = bytes.pack("C*")
    socket << data
  end

  def close
    @socket.close
  end
end
