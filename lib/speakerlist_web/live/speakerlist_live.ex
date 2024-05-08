defmodule SpeakerlistWeb.SpeakerlistLive do
  use SpeakerlistWeb, :live_view

  @topic "list"
  @timer_interval 100
  @interval 1000
  @topics_name {:via, Registry, {Registry.Agents, "topics"}}
  @stats_name {:via, Registry, {Registry.Agents, "stats"}}


  def render(assigns) do
    ~H"""
      <div class="z-0 px-20 mx-auto max-w-full h-56 grid grid-cols-2 gap-20 content-start" phx-window-keyup={show_modal("new-topic-modal")} phx-key="+">
        <div phx-window-keyup="key">
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
          <div class="grid grid-cols-2 gap-2 absolute bottom-20 w-2/3">
            <.simple_form for={@form} phx-submit="save" class="w-full">
              <.input id="name-input" field={@form[:name]} label="Namn" autocomplete="off" autofocus="true" phx-hook="ValidateName" phx-window-keyup={JS.focus()} phx-key="AltGraph"/>
            </.simple_form>
            <.simple_form for={@adjourn_form} phx-submit="new-adjourn-time" class="w-48">
              <.input field={@adjourn_form[:new_time]} label="Minuter att ajournera" autocomplete="off" autofocus="true"/>
          </.simple_form>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-4 content-start">
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
        <div class="grid grid-cols-2 absolute bottom-[80px] right-[110px] w-5/12 h-40 rounded-lg bg-[#b4b4b4] z-5"></div>
        <div class="grid grid-cols-2 absolute bottom-[84px] right-[112px] w-5/12 h-40 rounded-lg font-mono text-base/loose whitespace-pre-line bg-[#d8d0da] z-5">
          <div class="m-5">+ : New topic
          - : Pop topic
          . : Start/stop speaker time
          § : Dequeue speaker
          </div>
          <div class="m-5"> &#60 : Save stats to file
          &#62 : Load stats from file
          AltGr : Focus name input
          Insert : Adjourn
          </div>
        </div>
      </div>
      <.modal id="new-topic-modal" >
        <div phx-window-keyup={hide_modal("new-topic-modal")} phx-key="Enter">
          <.simple_form for={@modal_form} phx-submit="new-topic">
            <.input field={@modal_form[:new_topic]} label="Nytt Ämne" autocomplete="off" autofocus="true"/>
          </.simple_form>
        </div>
      </.modal>
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
    :timer.send_interval(@interval, self(), :time)

    stats = Stats.get_all_speakers(@stats_name)
    speakers = TopicStack.get_all_speakers(@topics_name)
    {:ok, assign(socket,
      speakers: speakers,
      stats_time: Enum.sort(stats, &(&1.time >= &2.time)),
      stats_count: Enum.sort(stats, &(&1.count >= &2.count)),
      form: to_form(%{"name" => ""}),
      modal_form: to_form(%{"new_topic" => ""}),
      adjourn_form: to_form(%{"new_time" => ""}),
      inner_block: "",
      speaker_time: ~T[00:00:00.0],
      curr_speaker: nil,
      time: ~T[00:00:00],
      paused: true,
      timer: make_ref(),
      curr_topic: TopicStack.peek_name(@topics_name),
      adjourned: false,
      adjourn_time: ~T[00:00:00]
    )}
  end

  def handle_event("save", %{"name" => name}, socket) do
    if name == "" do
      {:noreply, socket}
    else
      TopicStack.add_speaker(@topics_name, String.capitalize(name))
      speakers = TopicStack.get_all_speakers(@topics_name)
      state = [form: to_form(%{"name" => ""}), speakers: speakers, curr_speaker: TopicStack.peek_curr(@topics_name)]

      SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
      {:noreply, assign(socket, state)}
    end
  end

  def handle_event("new-topic", %{"new_topic" => new_topic}, socket) do
    capped_topic = String.capitalize(new_topic)
    TopicStack.new_topic(@topics_name, capped_topic)
    new_speakers = TopicStack.get_all_speakers(@topics_name)
    state = [curr_topic: capped_topic, speakers: new_speakers, curr_speaker: nil]
    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
    {:noreply, assign(socket, state)}
  end

  def handle_event("new-adjourn-time", %{"new_time" => new_time}, socket) do
    state = [adjourn_time: Time.add(socket.assigns.time, elem(Integer.parse(new_time), 0) * 60, :second)]
    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
    {:noreply, assign(socket, state)}
  end

  def handle_event("key", %{"key" => "-"}, socket) do
    state = case TopicStack.pop_topic(@topics_name) do
      :error -> %{}
      :ok -> %{curr_topic: TopicStack.peek_name(@topics_name), speakers: TopicStack.get_all_speakers(@topics_name), curr_speaker: TopicStack.peek_curr(@topics_name)}
    end
    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
    {:noreply, assign(socket, state)}
  end

  def handle_event("key", %{"key" => "Insert"}, socket) do
    new_value = not socket.assigns.adjourned
    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", %{adjourned: new_value, adjourn_time: socket.assigns.adjourn_time})
    {:noreply, assign(socket, adjourned: new_value)}
  end

  def handle_event("key", %{"key" => "."}, socket) do
    state = case socket.assigns.paused && socket.assigns.curr_speaker != nil do
      true ->
        {:ok, ref} = :timer.send_interval(@timer_interval, self(), :tick)
        %{timer: ref, paused: false}
      false ->
        :timer.cancel(socket.assigns.timer)
        %{paused: true}
    end
    {:noreply, assign(socket, state)}
  end

  def handle_event("key", %{"key" => "§"}, socket) do
    if !socket.assigns.paused, do: :timer.cancel(socket.assigns.timer)

    {new_speakers, stats, curr} = case {socket.assigns.curr_speaker, TopicStack.dequeue_speaker(@topics_name)} do
      {nil, _} ->
        IO.puts("Cannot dequeue speaker, queue is empty")
        {socket.assigns.speakers,
        Stats.get_all_speakers(@stats_name),
        nil}
      {curr, {speaker, speakers}} ->
        {speakers,
        Stats.speaker_add_time(@stats_name, curr, socket.assigns.speaker_time),
        speaker}
    end

    state = [
      form: to_form(%{}),
      stats_time: Enum.sort(stats, &case Time.compare(&1.time, &2.time) do :gt -> true;  _ -> false end),
      stats_count: Enum.sort(stats, &(&1.count >= &2.count)),
      speaker_time: ~T[00:00:00.0],
      paused: true,
      speakers: new_speakers,
      curr_speaker: curr
    ]

    SpeakerlistWeb.Endpoint.broadcast_from(self(), @topic, "update", state)
    {:noreply, assign(socket, state)}
  end

  def handle_event("key", %{"key" => "<"}, socket) do
    prev = Jason.decode!(File.read!("save.json"))
    new = Stats.get_all_speakers(@stats_name)
      |> Enum.map(fn person -> {String.to_atom(person.name), Map.delete(person, :name)} end)
      |> :maps.from_list()
    File.write!("save.json", Jason.encode!(Map.merge(prev, new), [pretty: true]))
    {:noreply, socket}
  end

  def handle_event("key", %{"key" => ">"}, socket) do
    fromFile = File.read!("save.json") |> Jason.decode!()
    Stats.set_from_map(@stats_name, fromFile)
    stats = Stats.get_all_speakers(@stats_name)
    {:noreply, assign(socket,
      stats_count: Enum.sort(stats, &(&1.count >= &2.count)),
      stats_time: Enum.sort(stats, &case Time.compare(&1.time, &2.time) do :gt -> true;  _ -> false end))
    }
  end

  def handle_event("key", _params, socket) do
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
