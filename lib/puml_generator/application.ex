defmodule PumlGenerator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PumlGeneratorWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PumlGenerator.PubSub},
      # Start the Endpoint (http/https)
      PumlGeneratorWeb.Endpoint
      # Start a worker by calling: PumlGenerator.Worker.start_link(arg)
      # {PumlGenerator.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PumlGenerator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PumlGeneratorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
