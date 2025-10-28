defmodule PrivateModuleTest do
  use ExUnit.Case, async: false
  require TestProject

  test "compile test project" do
    TestProject.setup(:test1)

    TestProject.insert_code(:test1, fn ns ->
      """
      defmodule #{ns}.Demo do
        def hello do
        end
      end
      """
    end)

    assert TestProject.compile(:test1) == :ok
  end

  test "module not allowed to call private module" do
    TestProject.setup(:test2)

    TestProject.insert_code(:test2, fn ns ->
      """
      defmodule #{ns}.DemoNotAllowed do
        def hello do
          #{ns}.Demo.Private.hello()
        end
      end

      defmodule #{ns}.Demo.Private do
        use PrivateModule
        def hello do
          :hello
        end
      end
      """
    end)

    {:error, error} = TestProject.compile(:test2)

    assert error =~
             ~r/Module Elixir.Test2.DemoNotAllowed is not allowed to call private module Elixir.Test2.Demo.Private/
  end

  test "module allowed to call private module" do
    TestProject.setup(:test3)

    TestProject.insert_code(:test3, fn ns ->
      """
      defmodule #{ns}.Demo do
        def hello do
          #{ns}.Demo.Private.hello()
        end
      end

      defmodule #{ns}.Demo.Private do
        use PrivateModule
        def hello do
          :hello
        end
      end
      """
    end)

    assert TestProject.compile(:test3) == :ok
  end
end
