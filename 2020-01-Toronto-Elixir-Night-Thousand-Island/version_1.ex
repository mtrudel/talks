defmodule SocketServer do
  def run do
    {:ok, listen_socket} = :gen_tcp.listen(4000, [active: false])  # Listen (this binds the port)
    accept(listen_socket)
  end

  defp accept(listen_socket) do
    {:ok, connection_socket} = :gen_tcp.accept(listen_socket)      # Accept (this waits for a connection)
    :gen_tcp.send(connection_socket, "Hello, World")               # Interact with the client
    :gen_tcp.close(connection_socket)                              # Close the connection 
    accept(listen_socket)                                          # Listen for the next connection
  end
end
SocketServer.run
