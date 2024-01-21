defmodule SpeakerlistWeb.SpeakerlistLive do
  use SpeakerlistWeb, :live_view

  @topic "list"
  @timer_interval 100
  @interval 1000

  def render(assigns) do
    ~H"""
    <div class="px-20 mx-auto max-w-full h-56 grid grid-cols-2 gap-20 content-start" phx-window-keyup="key">
      <div>
        <.table rows={@speakers} id="table-prim">
          <:col :let={person} label="Näst på tur">
            <%= person%>
          </:col>
          <:col :let={person} label="">
            <%= case person == Enum.at(@speakers, 0, false) do %>
              <% true -> %>
                <div class="font-bold w-0"><%= :binary.part("#{@speaker_time}", 3, 7)%></div>
              <% false -> %>
                <%= ""%>
            <% end %>
          </:col>
        </.table>
        <.simple_form for={@form} phx-submit="save" class="absolute bottom-20 w-5/12" phx-change="validate">
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

    :timer.send_interval(@interval, self(), :time)

    stats = Stats.get_all_speakers(stats_name)
    speakers = TopicStack.get_all_speakers(topics_name)
    {:ok, assign(socket,
      speakers: speakers,
      stats_time: Enum.sort(stats, &(&1.time >= &2.time)),
      stats_count: Enum.sort(stats, &(&1.count >= &2.count)),
      form: to_form(%{"name" => ""}),
      inner_block: "",
      speaker_time: ~T[00:00:00.0],
      time: ~T[00:00:00],
      paused: true,
      timer: make_ref()
      #|> assign(:as, :name)
    )}
  end

  def handle_event("validate", %{"name" => name}, socket) do
    state = IO.inspect(to_form(%{"name" => String.replace(name, ~r/['.§+-]+/, "")}))
    {:noreply, assign(socket, :form, state)}
  end

  def handle_event("save", %{"name" => name}, socket) do
    if name == "" do
      {:noreply, socket}
    else
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    TopicStack.add_speaker(topics_name, String.capitalize(name))
    speakers = TopicStack.get_all_speakers(topics_name)
    state = [form: to_form(%{"name" => ""}), speakers: speakers]

    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
    {:noreply, assign(socket, state)}
    end
  end

  def handle_event("key", %{"key" => "."}, socket) do
    state = case socket.assigns.paused && !Enum.empty?(socket.assigns.speakers) do
      true ->
        {:ok, ref} = :timer.send_interval(@timer_interval, self(), :tick)
        %{timer: ref, paused: false}
      false ->
        :timer.cancel(socket.assigns.timer)
        %{paused: true}
    end
    {:noreply, assign(socket, Map.put(state, :form, to_form(%{"name" => ""})))}
  end

  def handle_event("key", %{"key" => "Delete"}, socket) do
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}

    if !socket.assigns.paused, do: :timer.cancel(socket.assigns.timer)

    {new_speakers, stats} = case TopicStack.dequeue_speaker(topics_name) do
      {:error, :nil} ->
        IO.puts(:stderr, "Cannot dequeue speaker, queue is empty")
        {socket.assigns.speakers, Stats.get_all_speakers(stats_name)}
      {speaker, speakers} ->
        {speakers,
        Stats.speaker_add_time(stats_name, speaker, socket.assigns.speaker_time)}
    end

    state = [
      form: to_form(%{}),
      stats_time: Enum.sort(stats, &case Time.compare(&1.time, &2.time) do :gt -> true;  _ -> false end),
      stats_count: Enum.sort(stats, &(&1.count >= &2.count)),
      speaker_time: ~T[00:00:00.0],
      paused: true,
      speakers: new_speakers
    ]

    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
    {:noreply, assign(socket, state)}
  end

  def handle_event("key", %{"key" => key}, socket) do
    IO.puts(key)
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    new_time = Time.add(socket.assigns.speaker_time, @timer_interval, :millisecond)
    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", %{speaker_time: new_time})
    {:noreply, assign(socket, speaker_time: new_time)}
  end

  def handle_info(:time, socket) do
    new_time = DateTime.now!("Europe/Stockholm") |> DateTime.to_time()
    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", %{time: new_time})
    {:noreply, assign(socket, time: new_time)}
  end
end
