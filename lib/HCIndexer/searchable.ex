defmodule HCIndexer.Searchable do
  @moduledoc """
  Module which purpose is to be used in other modules. It provides functions to
  make ElasticSeach communication easier
  """

  defmacro __using__(_) do
    quote do
      use HCIndexer.Settings
      use HCIndexer.Mapping
      use HCIndexer.Index
      use HCIndexer.Search
    end
  end
end
