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
        compilers: [:private_module] ++ Mix.compilers(),
        elixirc_options: [warnings_as_errors: true]
      ]
    end

    # ...

    defp deps do
      [
        {:private_module, "~> 0.1", runtime: false},
      ]
    end

    # ...
  end
  ```

  The following code defines a basic usage:

  ```elixir
  defmodule Implementation do
    defmodule State do
      # Private module only allowed to be used within the parent module.
      # If the module is used outside the parent module, it will raise an error at compile time.
      use PrivateModule
    end
  end
  ```


  """

  defmacro __using__(_opts) do
    quote do
      def __private_module__, do: true
    end
  end
end
