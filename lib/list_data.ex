defmodule ListData do
  require Record
  Record.defrecord(:list_data, name: "Nytt Ämne", primary: :queue.new, secondary: :queue.new, spoken: %{})
end
