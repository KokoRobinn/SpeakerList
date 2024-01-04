defmodule SpeakerlistWeb.SpeakerlistHTML do
  use SpeakerlistWeb, :html

  embed_templates "speakerlist_html/*"

  attr :messenger, :string

  def greet(assigns) do
    ~H"""
    <h2>Hello World, from <%= @messenger %>!</h2>
    """
  end

  def time(assigns) do
    ~H"
    <%= DateTime.to_time(DateTime.utc_now()) %>"
  end
end
