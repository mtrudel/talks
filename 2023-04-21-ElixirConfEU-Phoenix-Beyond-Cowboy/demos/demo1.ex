Mix.install([:plug, :websock_adapter, :bandit])

defmodule UpcaseServer do
  def init(_args) do
    {:ok, %{}}
  end

  def handle_in({msg, [opcode: :text]}, state) do
    {:push, {:text, String.upcase(msg)}, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end

defmodule MyPlug do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, """
    Use the JavaScript console to interact using websockets

    sock  = new WebSocket("ws://localhost:4000/websocket")
    sock.addEventListener("message", console.log)
    """)
  end

  get "/websocket" do
    WebSockAdapter.upgrade(conn, UpcaseServer, [], timeout: 60_000)
  end
end

Bandit.start_link(plug: MyPlug)
