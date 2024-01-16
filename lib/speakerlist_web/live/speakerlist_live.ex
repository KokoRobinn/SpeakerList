defmodule SpeakerlistWeb.SpeakerlistLive do
  alias Phoenix.LiveView
  use SpeakerlistWeb, :live_view

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
      |> assign(:form, to_form(%{"name" => ""}))
      |> assign(:inner_block, "")
      |> assign(:speaker_time, 0)
      #|> assign(:as, :name)
    }
  end

  def handle_event("save", %{"name" => name}, socket) do
    if name == "" do
      {:noreply, socket}
    else
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    TopicStack.add_speaker(topics_name, capitalize(name))
    prim = TopicStack.peek_prim(topics_name)
    sec = TopicStack.peek_sec(topics_name)
    {:noreply, socket
      |> assign(:form, to_form(%{}))
      |> assign(:prim, prim)
      |> assign(:sec, sec)
    }
    end
  end

  def handle_event("key", %{"key" => "§"}, socket) do
    topics_name = {:via, Registry, {Registry.Agents, "topics"}}
    stats_name = {:via, Registry, {Registry.Agents, "stats"}}
    IO.inspect(socket)
    case TopicStack.dequeue_speaker(topics_name) do
      {:error, :nil} ->
        IO.puts(:stderr, "Cannot dequeue speaker, queue is empty")
        {:noreply, socket}
      {:sec, {speaker, sec}} ->
        stats = Stats.speaker_add_time(stats_name, speaker, socket.assigns.speaker_time)
        {:noreply, socket
          |> assign(:form, to_form(%{}))
          |> assign(:sec, sec)
          |> assign(:stats_time, Enum.sort(stats, &(&1.time >= &2.time)))
          |> assign(:stats_count, Enum.sort(stats, &(&1.count >= &2.count)))
        }
      {:prim, {speaker, prim}} ->
        stats = Stats.speaker_add_time(stats_name, speaker, socket.assigns.speaker_time)
        {:noreply, socket
          |> assign(:form, to_form(%{}))
          |> assign(:prim, prim)
          |> assign(:stats_time, Enum.sort(stats, &(&1.time >= &2.time)))
          |> assign(:stats_count, Enum.sort(stats, &(&1.count >= &2.count)))
        }
    end
  end

  def handle_event("key", %{"key" => key}, socket) do
    IO.puts(key)
    {:noreply, socket}
  end

  @spec capitalize(binary()) :: binary()
  defp capitalize(<<first::binary-size(1), rest::binary>>) do
    String.upcase(first) <> rest
  end
end
