defmodule SpeakerlistWeb.SpeakerlistPublicLive do
  alias Phoenix.LiveView
  use SpeakerlistWeb, :live_view

  @topic "list"

  def render(assigns) do
    ~H"""
    <div class="px-20 mx-auto max-w-full h-56 grid grid-cols-2 gap-20 content-start">
      <div>
        <.table rows={@prim} id="table-prim">
          <:col :let={person} label="Näst på tur">
            <%= person%>
          </:col>
        </.table>
        <.table rows={@sec} id="table-sec">
          <:col :let={person} label="">
            <%= person%>
          </:col>
        </.table>
      </div>
      <div class="h-56 grid grid-cols-2 gap-4 content-start">
        <.table rows={@stats_time} id={"table-stats-time"}>
          <:col :let={person} label="Talartid">
            <%= person.name%>
          </:col>
          <:col :let={person} label="">
            <%= person.time%>
          </:col>
        </.table>
        <.table rows={@stats_count} id={"table-stats-count"}>
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
    SpeakerlistWeb.Endpoint.subscribe(@topic)

    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}

    stats = Stats.get_all_speakers(stats_name)
    prim = TopicStack.peek_prim(topics_name)
    sec = TopicStack.peek_sec(topics_name)
    {:ok,
      socket
      |> assign(:prim, prim)
      |> assign(:sec, sec)
      |> assign(:stats_time, Enum.sort(stats, &(&1.time >= &2.time)))
      |> assign(:stats_count, Enum.sort(stats, &(&1.count >= &2.count)))
      |> assign(:inner_block, "")
      |> assign(:speaker_time, 0)
      #|> assign(:as, :name)
    }
  end

  def handle_event("update", unsigned_params, socket) do

  end
end
