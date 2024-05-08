defmodule TopicStack do
  @moduledoc"""
    Stack for storing the topics along with some convenient functions
  """
require ListData

  def start_link(opts) do
    Agent.start_link(fn -> [] end, opts)
  end

  def new_topic(agent, name) do
    {:ok, t} = Topic.start_link(name)
    Agent.update(agent, &[t | &1])
    {:ok, t}
  end

  def pop_topic(agent) do
    Agent.get_and_update(agent, fn l -> pop(l) end)
  end

  def pop(list) do
    case list do
      [_head | [throat | tail]]->
        {:ok, [throat | tail]}
      _ -> {:error, []}
    end
  end

  defp peek_topic(agent) do
    Agent.get(agent, fn l -> safe_peek(l, & &1, ListData.list_data()) end)
  end

  @spec peek_name(pid() | {:via, atom(), any()}) :: String.t()
  def peek_name(agent) do
    Agent.get(agent, fn l -> safe_peek(l, &Topic.name/1, "") end)
  end

  def peek_prim(agent) do
    Agent.get(agent, fn l -> safe_peek(l, &Topic.primary/1, []) end)
  end

  def peek_sec(agent) do
    Agent.get(agent, fn l -> safe_peek(l, &Topic.secondary/1, []) end)
  end

  def peek_curr(agent) do
    Agent.get(agent, fn s -> safe_peek(s, &Topic.curr/1, nil) end)
  end

  def get_all_speakers(agent) do
    peek_prim(agent) ++ peek_sec(agent)
  end

  defp safe_peek(list, fun, fail) do
    case list do
      [head | _tail] ->
        fun.(head)
      _ -> fail
    end
  end

# Following are the functions that interface directly with the top topic

  def add_speaker(agent, name) do
    peek_topic(agent)
    |> Topic.add_speaker(name)
  end

  def dequeue_speaker(agent) do
    peek_topic(agent)
    |> Topic.dequeue_speaker()
  end
end
