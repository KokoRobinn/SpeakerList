defmodule SpeakerlistWeb.SpeakerlistLive do
  use SpeakerlistWeb, :live_view
  import TopicStack
  import ListData

  def render(assigns) do
    ~H"""
    <%= "#{@listdata}"%>
    <br/>
    <br/>
    <button phx-click="dec_temperature">-</button>
    Current temperature: <%= @temperature %>°C
    <button phx-click="inc_temperature">+</button>
    <br/>
    <br/>
    <.table rows={@list} id={"tabell"}>
      <:col :let={person} label="Name">
        <%= person.name%>
      </:col>
      <:col :let={person} label="Occupation">
        <%= person.type%>
      </:col>
      <:col :let={person} label="Status">
        <%= person.status%>
      </:col>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    temperature = 20 # Let's assume a fixed temperature for now
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    name = TopicStack.peek_name(topics_name)
    {:ok,
      socket
      |> assign(:listdata, name)
      |> assign(:temperature, temperature)
      |> assign(:list, [%{name: "Kenobi", type: "Jedi", status: "Alive"}, %{name: "General Grievous", type: "Villain", status: "Dead"}])
    }
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  def handle_event("dec_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 - 1))}
  end
end
