defmodule PrivateModule do
  defmacro __using__(_opts) do
    quote do
      @before_compile PrivateModule
    end
  end

  defmacro __before_compile__(_env) do
    quote do
    end
  end
end
