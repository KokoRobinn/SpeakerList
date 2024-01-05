defmodule Speakerlist.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SpeakerlistWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Speakerlist.PubSub},
      # Start Finch
      {Finch, name: Speakerlist.Finch},
      # Start the Endpoint (http/https)
      SpeakerlistWeb.Endpoint
      # Start a worker by calling: Speakerlist.Worker.start_link(arg)
      # {Speakerlist.Worker, arg}
    ]

    {:ok, _} = Registry.start_link(keys: :unique, name: Registry.Agents)
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    TopicStack.start_link(name: topics_name)
    Stats.start_link(name: stats_name)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Speakerlist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SpeakerlistWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
