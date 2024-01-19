defmodule SpeakerlistWeb.SpeakerlistLive do
  use SpeakerlistWeb, :live_view

  @topic "list"

  def render(assigns) do
    ~H"""
    <div class="px-20 mx-auto max-w-full h-56 grid grid-cols-2 gap-20 content-start" phx-window-keyup="key">
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
        <.simple_form for={@form} phx-submit="save" class="absolute bottom-20 w-5/12">
          <.input field={@form[:name]} label="Namn" autocomplete="off" autofocus="true"/>
        </.simple_form>
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
    """
  end

  def mount(_params, _session, socket) do
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}

    stats = Stats.get_all_speakers(stats_name)
    prim = TopicStack.peek_prim(topics_name)
    sec = TopicStack.peek_sec(topics_name)
    {:ok, assign(socket,
      prim: prim,
      sec: sec,
      stats_time: Enum.sort(stats, &(&1.time >= &2.time)),
      stats_count: Enum.sort(stats, &(&1.count >= &2.count)),
      form: to_form(%{"name" => ""}),
      inner_block: "",
      speaker_time: ~T[00:00:00],
      paused: true
      #|> assign(:as, :name)
    )}
  end

  def handle_event("save", %{"name" => name}, socket) do
    if name == "" do
      {:noreply, socket}
    else
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    TopicStack.add_speaker(topics_name, String.capitalize(name))
    prim = TopicStack.peek_prim(topics_name)
    sec = TopicStack.peek_sec(topics_name)
    state = [form: to_form(%{}), prim: prim, sec: sec]

    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
    {:noreply, assign(socket, state)}
    end
  end

  def handle_event("key", %{"key" => "."}, socket) do
    state = case socket.assigns.paused do
      true -> %{speaker_time: Time.add(socket.assigns.speaker_time, -DateTime.to_unix(DateTime.now!("Europe/Stockholm"))), paused: false}
      false -> %{speaker_time: Time.add(socket.assigns.speaker_time, DateTime.to_unix(DateTime.now!("Europe/Stockholm"))), paused: true}
    end
    {:noreply, assign(socket, state)}
  end

  def handle_event("key", %{"key" => "Delete"}, socket) do
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}

    time = case socket.assigns.paused do
      true -> socket.assigns.speaker_time
      false -> Time.add(socket.assigns.speaker_time, DateTime.to_unix(DateTime.now!("Europe/Stockholm")))
    end

    {new_q, stats} = case TopicStack.dequeue_speaker(topics_name) do
      {:error, :nil} ->
        IO.puts(:stderr, "Cannot dequeue speaker, queue is empty")
        socket.assigns.stats
      {:sec, {speaker, sec}} ->
        {{:sec, sec},
        Stats.speaker_add_time(stats_name, speaker, time)}
      {:prim, {speaker, prim}} ->
        {{:prim, prim},
        Stats.speaker_add_time(stats_name, speaker, time)}
    end
    state = [
      form: to_form(%{}),
      stats_time: Enum.sort(stats, &(&1.time >= &2.time)),
      stats_count: Enum.sort(stats, &(&1.count >= &2.count)),
      speaker_time: ~T[00:00:00],
      paused: true] ++
      [new_q]

    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
    {:noreply, assign(socket, state)}
  end

  def handle_event("key", %{"key" => key}, socket) do
    IO.puts(key)
    {:noreply, socket}
  end
end
