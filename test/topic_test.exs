defmodule TopicTest do
  use ExUnit.Case
  doctest Topic

  test "primary" do
    {:ok, topic} = Topic.start_link("test")
    Topic.add_speaker(topic, "bah")
    q = :queue.new
    assert Topic.primary(topic) == :queue.in("bah", q)
  end

  test "secondary and primary" do
    {:ok, topic} = Topic.start_link("test")
    {:ok, no_speaker} = Topic.dequeue_speaker(topic)
    Topic.add_speaker(topic, "bah")
    {:ok, _bah_first} = Topic.dequeue_speaker(topic)
    Topic.add_speaker(topic, "bah")
    Topic.add_speaker(topic, "boh")
    {:ok, firstpop} = Topic.dequeue_speaker(topic)
    {:ok, secondpop} = Topic.dequeue_speaker(topic)
    assert {no_speaker, firstpop, secondpop} == {:nil, "boh", "bah"}
  end
end
