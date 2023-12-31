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

  @spec dequeue_speaker(pid()) :: {:ok, any()}
  def dequeue_speaker(agent) do
    {:list_data, _name, primary, secondary, _spoken} = Agent.get(agent, fn state -> state end)
    case {:queue.len(primary), :queue.len(secondary)} do
      {0, 0} ->
        {:ok, :nil}
      {0, _sec} ->
        {{:value, speaker}, new_secondary} = :queue.out(secondary)
        Agent.update(agent, &list_data(&1, secondary: new_secondary))
        {:ok, speaker}
      {_prim, _sec} ->
        {{:value, speaker}, new_primary} = :queue.out(primary)
        Agent.update(agent, &list_data(&1, primary: new_primary))
        {:ok, speaker}
    end
  end

  def name(agent) do
    Agent.get(agent, &list_data(&1, :name))
  end

  def primary(agent) do
    Agent.get(agent, &list_data(&1, :primary))
  end

  def secondary(agent) do
    Agent.get(agent, &list_data(&1, :secondary))
  end

  def has_spoken?(agent, speaker) do
    Map.get(Agent.get(agent, &list_data(&1, :spoken)), speaker)
  end
end
