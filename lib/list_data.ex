defmodule ListData do
  require Record
  Record.defrecord(:list_data, name: "Lista", primary: :queue.new, secondary: :queue.new, spoken: %{})
end
