defmodule Mix.Tasks.Compile.PrivateModule do
  use Mix.Task.Compiler
  require Mix.Compilers.Elixir

  defmodule CompilerState do
    use GenServer

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    @impl true
    def init(_opts) do
      :ets.new(__MODULE__, [:set, :public, :named_table])
      {:ok, %{}}
    end

    def add_dependency(from, to) do
      :ets.insert(__MODULE__, {{from, to}, to})
      :ok
    end

    def select_dependencies(criteria_fun) do
      :ets.tab2list(__MODULE__)
      |> Enum.map(&elem(&1, 0))
      |> Enum.filter(criteria_fun)
    end
  end

  @recursive true
  @impl Mix.Task.Compiler
  def run(_argv) do
    {:ok, _} = CompilerState.start_link()

    Mix.Task.Compiler.after_compiler(:elixir, &after_elixir_compiler/1)
    Mix.Task.Compiler.after_compiler(:app, &after_app_compiler/1)
    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, [__MODULE__ | tracers])
    {:ok, []}
  end

  def trace({remote, _, to_module, _name, _arity}, env)
      when remote in [:remote_function, :local_function] and
             to_module not in [:elixir_utils, :elixir_module, Module, :elixir_def] do
    CompilerState.add_dependency(env.module, to_module)
    :ok
  end

  def trace(_trace, _env) do
    :ok
  end

  defp after_elixir_compiler(outcome) do
    tracers = Enum.reject(Code.get_compiler_option(:tracers), &(&1 == __MODULE__))
    Code.put_compiler_option(:tracers, tracers)
    outcome
  end

  defp after_app_compiler(outcome) do
    {_, sources} =
      Mix.Compilers.Elixir.read_manifest(Path.join(Mix.Project.manifest_path(), "compile.elixir"))

    private_modules =
      Enum.filter(sources, fn source ->
        PrivateModule in Mix.Compilers.Elixir.source(source, :compile_references)
      end)
      |> Enum.map(fn source ->
        Mix.Compilers.Elixir.source(source, :modules)
      end)
      |> List.flatten()

    with {status, diagnostics} when status in [:ok, :noop] <- outcome do
      invalid_dependencies =
        CompilerState.select_dependencies(fn {source_module, to_module} ->
          not allowed_to_use_private_module?(source_module, to_module, private_modules)
        end)

      errors = Enum.map(invalid_dependencies, &diagnostic/1)

      if length(errors) > 0 do
        Mix.shell().info("")
        Enum.each(errors, &print_diagnostic_error/1)
        {:error, diagnostics ++ errors}
      else
        {:ok, diagnostics}
      end
    end
  end

  defp print_diagnostic_error(error) do
    Mix.shell().info([[:bright, :red, "#{error.severity}", " "], error.message, ""])
  end

  defp allowed_to_use_private_module?(source_module, to_module, private_modules) do
    private_scopes =
      Enum.map(private_modules, fn mod ->
        Module.split(mod) |> Enum.drop(-1) |> Module.concat()
      end)
      |> Enum.uniq()

    to_module in private_modules and source_module in private_scopes
  end

  defp diagnostic({source_module, to_module}) do
    %Mix.Task.Compiler.Diagnostic{
      compiler_name: "private_module",
      details: nil,
      file: nil,
      message: "Module #{source_module} is not allowed to call private module #{to_module}",
      position: 0,
      severity: :error
    }
    |> struct([])
  end
end
