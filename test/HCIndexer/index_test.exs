defmodule HCIndexer.IndexTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "search_settings" do
    defmodule Test do
      @moduledoc false
      use HCIndexer.Searchable

      mapping do
        property :id, :integer
      end

      search_settings %{test: "ok"}
    end

    assert Test.search_settings == %{test: "ok"}
  end
end
