defmodule SpeakerlistWeb.SpeakerlistController do
  use SpeakerlistWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"messenger" => messenger}) do
    conn
    |> assign(:messenger, messenger)
    |> render(:show)
  end
end
