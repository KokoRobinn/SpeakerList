defmodule SpeakerlistWeb.SpeakerlistHTML do
  use SpeakerlistWeb, :html

  embed_templates "speakerlist_html/*"

  attr :messenger, :string

  def greet(assigns) do
    ~H"""
    <h2>Hello World, from <%= @messenger %>!</h2>
    """
  end
end
