defmodule SpeakerlistWeb.SpeakerlistPublicLive do
  use SpeakerlistWeb, :live_view

  @topic "list"

  def render(assigns) do
    ~H"""
      <div class="px-20 mx-auto max-w-full h-56 grid grid-cols-2 gap-20 content-start">
        <div>
        <.table rows={[@curr_speaker] ++ @speakers} id="table-prim">
            <:col :let={person} label={@curr_topic}>
              <%= person%>
            </:col>
            <:col :let={person} label="">
              <%= case person == @curr_speaker && person != nil do %>
                <% true -> %>
                  <div class="font-bold w-0"><%= :binary.part("#{@speaker_time}", 3, 7)%></div>
                <% false -> %>
                  <%= ""%>
              <% end %>
            </:col>
          </.table>
        </div>
        <div class="h-56 grid grid-cols-2 gap-4 content-start">
          <.table rows={@stats_time} id={"table-stats-time"}>
            <:col :let={person} label="Talartid">
              <%= person.name%>
            </:col>
            <:col :let={person} label="">
              <%= :binary.part("#{person.time}", 3, 5)%>
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
      <%= if @adjourned do %>
        <div class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] z-10">
          <div class="absolute h-full w-full inline-flex animate-ping rounded-full bg-orange-500"></div>
          <div class="relative inline-flex h-full w-full items-center justify-center text-6xl font-black rounded-full bg-orange-500">
            Ajournerat till <%= :binary.part("#{@adjourn_time}", 0, 5) %>
          </div>
        </div>
      <% end %>
    """
  end

  def mount(_params, _session, socket) do
    SpeakerlistWeb.Endpoint.subscribe(@topic)

    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}

    stats = Stats.get_all_speakers(stats_name)
    prim = TopicStack.peek_prim(topics_name)
    sec = TopicStack.peek_sec(topics_name)
    {:ok, assign(socket,
      speakers: prim ++ sec,
      stats_time: Enum.sort(stats, &(&1.time >= &2.time)),
      stats_count: Enum.sort(stats, &(&1.count >= &2.count)),
      inner_block: "",
      speaker_time: ~T[00:00:00.0],
      time: ~T[00:00:00.0],
      adjourned: false,
      adjourn_time: "00:00",
      curr_topic: "Inget Ämne",
      curr_speaker: nil
    )}
  end

  def handle_info(%{topic: @topic, payload: state}, socket) do
    {:noreply, assign(socket, state)}
  end

  def handle_event("key", _params, socket) do
    {:noreply, socket}
  end
end
