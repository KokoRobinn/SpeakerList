defmodule SpeakerlistWeb.SpeakerlistLive do
  use SpeakerlistWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="px-20 mx-auto max-w-full h-56 grid grid-cols-2 gap-20 content-start" phx-key-down>
      <div>
        <.table rows={@prim} id="table-prim">
          <:col :let={person} label="Prio-kö">
            <%= person%>
          </:col>
        </.table>
        <.table rows={@sec} id="table-sec">
          <:col :let={person} label="Kö">
            <%= person%>
          </:col>
        </.table>
        <.simple_form for={@form} phx-submit="save" class="absolute bottom-20 w-5/12">
          <.input field={@form[:name]} label="Namn" autocomplete="off" autofocus="true"/>
        </.simple_form>
      </div>
      <div class="h-56 grid grid-cols-2 gap-4 content-start">
        <.table rows={@stats} id={"table-stats-time"}>
          <:col :let={person} label="Talartid">
            <%= person.name%>
          </:col>
          <:col :let={person} label="">
            <%= person.time%>
          </:col>
        </.table>
        <.table rows={@stats} id={"table-stats-count"}>
          <:col :let={person} label="Gånger i talarstolen">
            <%= person.name%>
          </:col>
          <:col :let={person} label="">
            <%= person.count%>
          </:col>
        </.table>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}
    stats = [%{name: "banan", count: 2, time: 1.23}]#Stats.get_all_speakers(stats_name)
    prim = TopicStack.peek_prim(topics_name)
    sec = TopicStack.peek_sec(topics_name)
    sec_list = :queue.to_list(sec)
    prim_list = :queue.to_list(prim)
    {:ok,
      socket
      |> assign(:prim, prim_list)
      |> assign(:sec, sec_list)
      |> assign(:stats, stats)
      |> assign(:form, to_form(%{"name" => ""}))
      |> assign(:inner_block, "")
      #|> assign(:as, :name)
    }
  end

  def handle_event("save", %{"name" => name}, socket) do
    if name == "" do
      {:noreply, socket}
    else
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    TopicStack.add_speaker(topics_name, name)
    prim = TopicStack.peek_prim(topics_name)
    prim_list = :queue.to_list(prim)
    {:noreply, socket
      |> assign(:form, to_form(%{}))
      |> assign(:prim, prim_list)
    }
    end
  end
end
