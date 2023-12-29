defmodule SpeakerlistWeb.PageController do
  alias Phoenix.LiveView.Plug
  use SpeakerlistWeb, :controller

  @spec home(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  @spec init(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def init(conn, _params) do
    {:ok, _} = Registry.start_link(keys: :unique, name: Registry.Agents)
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    TopicStack.start_link(name: topics_name)
    Stats.start_link(name: stats_name)
    conn
  end
end
