defmodule HCIndexer.Search do
  import HCIndexer.Request
  @moduledoc """
  Search in indexed results
  """

  defmacro __using__(_) do
    quote do
      def search(query), do: search(index(), query)
    end
  end

  def search(index, query) do
    base = "#{Atom.to_string(index)}/_search"
    case is_map(query) do
      true -> get(base, query)
      false -> get("#{base}?q=#{query}")
    end
  end
end
