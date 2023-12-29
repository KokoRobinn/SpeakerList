defmodule TopicStackTest do
  use ExUnit.Case
  doctest TopicStack

  test "push and pop" do
    {:ok, stack} = TopicStack.start_link()
    empty_pop = TopicStack.pop_topic(stack)
    TopicStack.new_topic(stack, "first")
    TopicStack.new_topic(stack, "second")
    assert empty_pop == :nil

    s = TopicStack.pop_topic(stack)
    f = TopicStack.pop_topic(stack)
    assert Topic.name(f) == "first"
    assert Topic.name(s) == "second"
  end

  test "peeks" do
    {:ok, stack} = TopicStack.start_link()
    TopicStack.new_topic(stack, "first")
    topic = TopicStack.peek_topic(stack)
    Topic.add_speaker(topic, "bah")
    topic_name = TopicStack.peek_name(stack)
    topic_prim = TopicStack.peek_prim(stack)
    topic_sec = TopicStack.peek_sec(stack)
    assert topic_name == "first"
    assert topic_prim == {["bah"], []}
    assert topic_sec == {[], []}
  end
end
