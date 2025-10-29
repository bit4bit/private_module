defmodule TestProject do
  @moduledoc false

  def setup(opts \\ []) do
    setup(:"test#{:erlang.unique_integer([:positive, :monotonic])}", opts)
  end

  def setup(app_name, opts) when is_atom(app_name) do
    File.rm_rf(project_path(app_name))
    File.mkdir_p!(project_path(app_name))
    File.mkdir_p!(Path.join(project_path(app_name), "lib"))
    init_mix(project_path(app_name), app_name, opts)

    app_name
  end

  def ns(app_name) do
    Macro.camelize(to_string(app_name))
  end

  defp init_mix(project_path, app_name, opts) do
    elixirc_options =
      Keyword.get(opts, :project, []) |> Keyword.get(:elixirc_options, []) |> inspect()

    mix_source = """
    defmodule #{ns(app_name)}.MixProject do
      use Mix.Project

      def project do
        [
          app: :#{app_name},
          version: "0.1.0",
          elixir: "~> 1.14",
          compilers: [:private_module] ++ Mix.compilers(),
          start_permanent: Mix.env() == :prod,
          elixirc_options: #{if String.length(elixirc_options) > 0, do: "#{elixirc_options},", else: ""}
          deps: deps()
        ]
      end

      # Run "mix help compile.app" to learn about applications.
      def application do
        [
          extra_applications: [:logger]
        ]
      end

      # Run "mix help deps" to learn about dependencies.
      defp deps do
        [
          {:private_module, path: "#{Path.absname(".")}", runtime: false}
        ]
      end
    end

    """

    File.write!(Path.join(project_path, "mix.exs"), mix_source)
  end

  def compile(app_name, args \\ []) do
    ref = make_ref()
    compile_pid = self()

    Mix.Project.in_project(app_name, project_path(app_name), fn _ ->
      Mix.Task.clear()
      send(compile_pid, {ref, Mix.Task.run("compile", ["--return-errors"] ++ args)})
    end)

    receive do
      {^ref, result} ->
        case result do
          {:ok, _} ->
            :ok

          {:error, diagnostics} ->
            {
              :error,
              Enum.map_join(diagnostics, "\n", & &1.message)
            }
        end
    after
      0 -> raise("result not received")
    end
  end

  def insert_code(app_name, fun) when is_atom(app_name) do
    File.write!(
      "#{project_path(app_name)}/lib/#{app_name}_test_project.ex",
      fun.(ns(app_name))
    )
  end

  defp project_path(app_name) do
    Path.absname("tmp/test_project_#{app_name}")
  end
end
