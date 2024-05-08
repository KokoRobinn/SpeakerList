defmodule ListData do
  require Record
  Record.defrecord(:list_data, name: "Nytt Ämne", curr: nil, primary: :queue.new, secondary: :queue.new, spoken: %{})
end
