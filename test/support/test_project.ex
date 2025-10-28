defmodule TestProject do
  def setup(app_name) when is_atom(app_name) do
    File.rm_rf(project_path(app_name))

    ExUnit.CaptureIO.capture_io(fn ->
      Mix.Task.clear()
      Mix.Tasks.New.run([project_path(app_name), "--app", app_name |> to_string()])
      init_mix(project_path(app_name), app_name)
    end)
  end

  defp init_mix(project_path, app_name) do
    mix_source = """
    defmodule Test1.MixProject do
      use Mix.Project

      def project do
        [
          app: :#{app_name},
          version: "0.1.0",
          elixir: "~> 1.14",
          compilers: [:private_module] ++ Mix.compilers(),
          start_permanent: Mix.env() == :prod,
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
          {:private_module, path: "#{Path.absname(".")}"}
        ]
      end
    end

    """

    File.write!(Path.join(project_path, "mix.exs"), mix_source)
  end

  defp add_dependencies(project_path, deps) do
    mix_exs_path = Path.join(project_path, "mix.exs")
    mix_exs = File.read!(mix_exs_path)

    deps_code =
      deps
      |> Enum.map(fn
        {name, opts} -> ":#{name}, #{inspect(opts)}"
        other -> inspect(other)
      end)
      |> Enum.map(&"{#{&1}}")
      |> Enum.join(",\n      ")

    updated_mix_exs =
      Regex.replace(
        ~r/defp deps do\s*\[.*?\]\s*end/s,
        mix_exs,
        "defp deps do\n    [\n      #{deps_code}\n    ]\n  end"
      )

    File.write!(mix_exs_path, updated_mix_exs)
  end

  def compile(app_name) do
    ref = make_ref()
    compile_pid = self()

    Mix.Project.in_project(app_name, project_path(app_name), fn _ ->
      ExUnit.CaptureIO.capture_io(fn ->
        Mix.Task.clear()
        send(compile_pid, {ref, Mix.Task.run("compile", ["--return-errors"])})
      end)
    end)

    receive do
      {^ref, result} ->
        case result do
          {:ok, _} ->
            :ok

          {:error, diagnostics} ->
            {
              :error,
              Enum.map(diagnostics, & &1.message) |> Enum.join("\n")
            }
        end
    after
      0 -> raise("result not received")
    end
  end

  def insert_code(app_name, body) when is_atom(app_name) do
    File.write!("#{project_path(app_name)}/lib/#{app_name}_test_project.ex", body)
  end

  defp project_path(app_name) do
    Path.absname("tmp/test_project_#{app_name}")
  end
end
