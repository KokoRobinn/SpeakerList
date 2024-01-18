defmodule Stats do
  def start_link(opts) do
    Agent.start_link(fn -> %{} end, opts)
  end

  @doc """
  Takes the PID of a stats agent as well as a name and a time to add
  and adds the time and increments the count of the speaker. It then returns
  all stats
  """
  def speaker_add_time(stats, name, new_time) do
    Agent.update(stats, &Map.update(&1, name, %{name: name, count: 1, time: new_time},
      fn %{count: count, time: time} = map -> %{map | count: count + 1, time: time + new_time} end))

    Agent.get(stats, &Map.values(&1))
  end

  def get_speaker(stats, name) do
    Agent.get(stats, &Map.get(&1, name))
  end

  def get_all_speakers(stats) do
    Agent.get(stats, &Map.values(&1))
  end
end
