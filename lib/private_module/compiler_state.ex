defmodule PrivateModule.CompilerState do
  @moduledoc false

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ets.new(__MODULE__, [:set, :public, :named_table])
    {:ok, %{}}
  end

  def add_dependency(from, to, ctx) do
    :ets.insert(__MODULE__, {{from, to, ctx}, to})
    :ok
  end

  def select_dependencies(criteria_fun) do
    Stream.unfold(
      :ets.first(__MODULE__),
      fn
        :"$end_of_table" -> nil
        key -> {key, :ets.next(__MODULE__, key)}
      end
    )
    |> Stream.filter(criteria_fun)
  end
end
