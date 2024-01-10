defmodule TopicStack do
  @moduledoc"""
    Stack for storing the topics along with some convenient functions
  """
require ListData

  def start_link(opts) do
    Agent.start_link(fn -> [] end, opts)
  end

  @spec new_topic(pid(), binary()) :: {:ok, pid()}
  def new_topic(agent, name) do
    {:ok, t} = Topic.start_link(name)
    Agent.update(agent, &[t | &1])
    {:ok, t}
  end

  @spec pop_topic(pid()) :: ListData.list_data()
  def pop_topic(agent) do
    Agent.get_and_update(agent, fn l -> pop(l) end)
  end

  defp pop(list) do
    case list do
      [head | tail]->
        {head, tail}
      _ -> {:nil, []}
    end
  end

  defp peek_topic(agent) do
    topic = Agent.get(agent, fn l -> safe_peek(l, & &1) end)
  end

  @spec peek_name(pid() | {:via, atom(), any()}) :: String.t()
  def peek_name(agent) do
    Agent.get(agent, fn l -> safe_peek(l, &Topic.name/1) end)
  end

  def peek_prim(agent) do
    Agent.get(agent, fn l -> safe_peek(l, &Topic.primary/1) end)
  end

  def peek_sec(agent) do
    Agent.get(agent, fn l -> safe_peek(l, &Topic.secondary/1) end)
  end

  def add_speaker(agent, name) do
    topic = peek_topic(agent)
    Topic.add_speaker(topic, name)
  end

  defp safe_peek(list, fun) do
    case list do
      [head | _tail] ->
        fun.(head)
      _ -> :nil
    end
  end
end
