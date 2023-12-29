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
    Agent.update(stats, &Map.update(&1, name, {1,0}, fn {count, time} -> {count + 1, time} end))
    {_count, time} = Agent.get(stats, &Map.get(&1, name))
    time
  end

  @spec get_count_and_time(pid(), binary()) :: {integer(), float()}
  def get_count_and_time(stats, name) do
    Agent.get(stats, &Map.get(&1, name))
  end
end
