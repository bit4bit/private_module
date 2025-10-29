defmodule PrivateModule do
  @moduledoc """
  PrivateModule is a library that allows to have the concept of private modules,
  where a PrivateModule is a module that can only be used within the parent module.

  ## Basic Usage

  Add PrivateModule as a dependency and enable compiler in `mix.exs`:

  ```elixir
  defmodule MySystem.MixProject do
    use Mix.Project

    # ...

    def project do
      [
        compilers: extra_compilers(Mix.env()) ++ Mix.compilers(),
        elixirc_options: [warnings_as_errors: true]
      ]
    end

    # ...
    defp extra_compilers(:prod), do: []
    defp extra_compilers(_), do: [:private_module]
    defp deps do
      [
        {:private_module, "~> 0.1", only: [:dev, :test], runtime: false},
      ]
    end

    # ...
  end
  ```

  The following code defines a basic usage:

  ```elixir
  defmodule Implementation do
    # ...

    defmodule State do
      # Private module only allowed to be used within the parent module.
      # If the module is used outside the parent module, it will raise an error at compile time.
      use PrivateModule
    end

    # ...
  end
  ```


  """

  defmacro __using__(_opts) do
    quote do
      def __private_module__, do: true
    end
  end
end
