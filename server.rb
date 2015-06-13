require './web_socket_server'

ws = WebSocketServer.new
conn = ws.accept
conn.send("Hello")
