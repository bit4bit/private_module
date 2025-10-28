defmodule PrivateModuleTest do
  use ExUnit.Case, async: false
  require TestProject

  test "compile test project" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
      """
      defmodule #{ns}.Demo do
        def hello do
        end
      end
      """
    end)

    assert TestProject.compile(test_project) == :ok
  end

  test "module not allowed to call private module" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
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

    {:error, error} = TestProject.compile(test_project)

    assert error =~
             ~r/Module Elixir.#{TestProject.ns(test_project)}.DemoNotAllowed is not allowed to call private module Elixir.#{TestProject.ns(test_project)}.Demo.Private/
  end

  test "module allowed to call private module" do
    test_project = TestProject.setup()

    TestProject.insert_code(test_project, fn ns ->
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
