defmodule PrivateModule.CompilerState do
  @moduledoc false

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ets.new(dependencies_table(), [:set, :public, :named_table])
    :ets.new(private_scopes_table(), [:set, :public, :named_table])
    :ets.new(private_module_table(), [:set, :public, :named_table])
    {:ok, %{}}
  end

  def add_dependency(from, to, ctx) do
    :ets.insert(dependencies_table(), {{from, to, ctx}, to})
    :ok
  end

  def add_private_module(module) do
    :ets.insert(private_module_table(), {module, true})
    :ok
  end

  def private_module?(module) do
    :ets.member(private_module_table(), module)
  end

  def add_private_scope(module) do
    :ets.insert(private_scopes_table(), {module, true})
    :ok
  end

  def belongs_private_scope?(module) do
    :ets.member(private_scopes_table(), module)
  end

  def select_dependencies(criteria_fun) do
    Stream.unfold(
      :ets.first(dependencies_table()),
      fn
        :"$end_of_table" -> nil
        key -> {key, :ets.next(dependencies_table(), key)}
      end
    )
    |> Stream.filter(criteria_fun)
  end

  defp private_module_table, do: :"#{__MODULE__}.PrivateModules"
  defp private_scopes_table, do: :"#{__MODULE__}.PrivateScopes"
  defp dependencies_table, do: :"#{__MODULE__}.Dependencies"
end
