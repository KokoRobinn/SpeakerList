defmodule Topic do
  use Agent
  import ListData

  @moduledoc """
  The module that tracks the speakers for one individual topic
  """

  @spec start_link(String.t()) :: {:ok, pid()}
  def start_link(name) do
    Agent.start_link(fn -> list_data(name: name) end)
  end

  @spec add_speaker(pid(), any()) :: :ok
  @doc """
  Expect :ok
  """
  def add_speaker(agent, speaker) do
    q = Agent.get(agent, fn state -> state end)
    spoken = list_data(q, :spoken)
    spoken? = Map.get(list_data(q, :spoken), speaker)
    Agent.update(agent, &list_data(&1, spoken: Map.put(spoken, speaker, true)))
    case spoken? do
      true ->
        Agent.update(agent, &list_data(&1, secondary: :queue.in(speaker, list_data(q, :secondary))))
      nil ->
        Agent.update(agent, &list_data(&1, primary: :queue.in(speaker, list_data(q, :primary))))
    end
  end

  def dequeue_speaker(agent) do
    {:list_data, _name, primary, secondary, _spoken} = Agent.get(agent, fn state -> state end)
    case {:queue.len(primary), :queue.len(secondary)} do
      {0, 0} ->
        {:error, :nil}
      {0, _sec} ->
        {{:value, speaker}, new_secondary} = :queue.out(secondary)
        Agent.update(agent, &list_data(&1, secondary: new_secondary))
        {speaker, :queue.to_list(primary) ++ :queue.to_list(new_secondary)}
      {_prim, _sec} ->
        {{:value, speaker}, new_primary} = :queue.out(primary)
        Agent.update(agent, &list_data(&1, primary: new_primary))
        {speaker, :queue.to_list(new_primary) ++ :queue.to_list(secondary)}
    end
  end

  def name(agent) do
    Agent.get(agent, &list_data(&1, :name))
  end

  def primary(agent) do
    Agent.get(agent, &list_data(&1, :primary))
    |> :queue.to_list()
  end

  def secondary(agent) do
    Agent.get(agent, &list_data(&1, :secondary))
    |> :queue.to_list()
  end

  def has_spoken?(agent, speaker) do
    Map.get(Agent.get(agent, &list_data(&1, :spoken)), speaker)
  end
end
