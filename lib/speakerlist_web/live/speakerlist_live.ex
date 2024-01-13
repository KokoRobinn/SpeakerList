defmodule SpeakerlistWeb.SpeakerlistLive do
  use SpeakerlistWeb, :live_view

  def render(assigns) do
    ~H"""
    <button phx-click="dec_temperature">-</button>
    Current temperature: <%= @temperature %>°C
    <button phx-click="inc_temperature">+</button>
    <br/>
    <br/>
    <.table rows={@list} id={"tabell"}>
      <:col :let={person} label="Name">
        <%= person%>
      </:col>
    </.table>
    <.simple_form for={@form} phx-submit="save">
      <.input field={@form[:name]} label="Namn" autocomplete="off"/>
      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    temperature = 20 # Let's assume a fixed temperature for now
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    prim = TopicStack.peek_prim(topics_name)
    prim_list = :queue.to_list(prim)
    {:ok,
      socket
      |> assign(:temperature, temperature)
      |> assign(:list, prim_list)
      |> assign(:form, to_form(%{"name" => ""}))
      |> assign(:inner_block, "")
      #|> assign(:as, :name)
    }
  end

  def handle_event("save", %{"name" => name}, socket) do
    IO.puts("saving")
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    TopicStack.add_speaker(topics_name, name)
    prim = TopicStack.peek_prim(topics_name)
    prim_list = :queue.to_list(prim)
    {:noreply, socket
      |> assign(:form, to_form(%{}))
      |> assign(:list, prim_list)
    }
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  def handle_event("dec_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 - 1))}
  end
end
