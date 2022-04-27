defmodule EmpexDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      EmpexDemoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: EmpexDemo.PubSub},
      # Start the Endpoint (http/https)
      EmpexDemoWeb.Endpoint
      # Start a worker by calling: EmpexDemo.Worker.start_link(arg)
      # {EmpexDemo.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EmpexDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EmpexDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
