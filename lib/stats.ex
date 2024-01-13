defmodule Stats do
  def start_link(opts) do
    Agent.start_link(fn -> %{} end, opts)
  end

  @doc """
  Takes the PID of a stats agent as well as a name in the form of a
  string and then returns the time the speaker has recorded as well
  as updates the number times the speaker has spoken
  """
  @spec speaker_start(pid(), binary()) :: integer()
  def speaker_start(stats, name) do
    Agent.update(stats, &Map.update(&1, name, %{name: name, count: 1, time: 0}, fn %{count: count} = map -> %{map | count: count + 1} end))
    %{time: time} = Agent.get(stats, &Map.get(&1, name))
    time
  end

  @spec get_speaker(pid(), binary()) :: map()
  def get_speaker(stats, name) do
    Agent.get(stats, &Map.get(&1, name))
  end

  def get_all_speakers(stats) do
    Agent.get(stats, &Map.values(&1))
  end
end
