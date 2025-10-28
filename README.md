# PrivateModule

This library check a compile time the private module. A private module is a module that can only be used by its parent module.

```elixir
defmodule Component do
  def call do
      Component.SubComponent.call()
  end
end

# Only allowed to be used by Component (Parent)
defmodule Component.SubComponent do
  use PrivateModule

  def call do
    :ok
  end
end

defmodule OtherComponent do
  def call do
    # Not allowed
    Component.SubComponent.call()
  end
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `private_module` to your list of dependencies in `mix.exs`:

```elixir
def project do
  ...
  compilers: [:private_module] ++ Mix.compilers()
  ...
end

def deps do
  [
    {:private_module, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/private_module>.
