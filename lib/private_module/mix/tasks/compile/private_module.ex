defmodule Mix.Tasks.Compile.PrivateModule do
  @moduledoc """
    Compiler that checks dependencies on private modules.
  """

  use Mix.Task.Compiler
  require Mix.Compilers.Elixir

  alias PrivateModule.CompilerState

  @impl Mix.Task.Compiler
  def run(argv) do
    {parsed_opts, _remaining_args, _invalid} =
      OptionParser.parse(argv, switches: [warnings_as_errors: :boolean])

    {:ok, _} = CompilerState.start_link()

    Mix.Task.Compiler.after_compiler(:elixir, &after_elixir_compiler/1)
    Mix.Task.Compiler.after_compiler(:app, &after_app_compiler(&1, parsed_opts))
    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, [__MODULE__ | tracers])
    {:ok, []}
  end

  def trace({remote, _, to_module, _name, _arity}, env)
      when remote in [:remote_function, :local_function] and
             to_module not in [:elixir_utils, :elixir_module, Module, :elixir_def] do
    CompilerState.add_dependency(env.module, to_module, %{file: env.file, line: env.line})
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

  defp after_app_compiler(outcome, parsed_opts) do
    private_modules = read_private_modules()

    with {status, diagnostics} when status in [:ok, :noop] <- outcome do
      invalid_dependencies =
        CompilerState.select_dependencies(fn {source_module, to_module, _ctx} ->
          not allowed_to_use_private_module?(source_module, to_module, private_modules)
        end)

      errors = Enum.map(invalid_dependencies, &diagnostic/1)

      if length(errors) > 0 do
        Mix.shell().info("")
        Enum.each(errors, &print_diagnostic_error/1)
        # only error when warnings-as-error is set
        if warnings_as_errors?(parsed_opts) do
          {:error, diagnostics ++ errors}
        else
          {:ok, diagnostics ++ errors}
        end
      else
        {:ok, diagnostics}
      end
    end
  end

  defp read_private_modules do
    {_, sources} =
      Mix.Compilers.Elixir.read_manifest(Path.join(Mix.Project.manifest_path(), "compile.elixir"))

    Enum.filter(sources, fn source ->
      PrivateModule in Mix.Compilers.Elixir.source(source, :compile_references) or
        PrivateModule in Mix.Compilers.Elixir.source(source, :runtime_references)
    end)
    |> Enum.map(fn source ->
      Mix.Compilers.Elixir.source(source, :modules)
    end)
    |> List.flatten()
    |> Enum.filter(fn module ->
      # why can't read attribute?
      Keyword.has_key?(module.__info__(:functions), :__private_module__)
    end)
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

    to_module not in private_modules or source_module in private_scopes
  end

  defp diagnostic({source_module, to_module, ctx}) do
    %Mix.Task.Compiler.Diagnostic{
      compiler_name: "private_module",
      details: nil,
      file: ctx.file,
      message:
        "Module #{source_module} is not allowed to call private module #{to_module}\n at #{ctx.file}:#{ctx.line}",
      position: ctx.line,
      severity: :error
    }
  end

  defp warnings_as_errors?(parsed_opts) do
    config_warnings_as_errors =
      Mix.Project.config()[:elixirc_options][:warnings_as_errors] || false

    cli_warnings_as_errors = Keyword.get(parsed_opts, :warnings_as_errors, false)

    config_warnings_as_errors || cli_warnings_as_errors
  end
end
