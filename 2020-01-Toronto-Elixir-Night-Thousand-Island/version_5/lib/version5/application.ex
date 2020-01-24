defmodule Version5.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {ThousandIsland, handler_module: ThousandIsland.Handlers.Echo}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Version5.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
