defmodule HCIndexer.MappingTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "mapping definition" do
    defmodule Test do
      @moduledoc false
      use HCIndexer.Mapping

      mapping [index: :test, type: :object] do
        property :name, :string
        property :description, :integer
      end
    end

    assert Test.mapping == %{
      description: %{type: "integer"},
      name: %{type: "string"}
    }
  end

  describe "index definition" do
    test "guessed by module name" do
      defmodule MyModule.Test do
        @moduledoc false
        use HCIndexer.Mapping
        mapping do
          property :name, :string
        end
      end

      alias MyModule.Test
      assert Test.index() == :test
    end
  end
end
