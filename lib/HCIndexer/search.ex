defmodule HCIndexer.Search do
  import HCIndexer.Request
  @moduledoc """
  Search in indexed results
  """

  defmacro __using__(_) do
    quote do
      import HCIndexer.Search

      @doc """
      Search in current ElasticSearch index, @see `HCIndexer.Search.search/2`
      """
      @spec search(map) ::
        {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
        {:error, HTTPoison.Error.t}
      def search(query), do: search(index(), query)
    end
  end

  @doc """
  Launch a search
  """
  @spec search(atom, map) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def search(index, query) do
    base = "#{Atom.to_string(index)}/_search"

    case is_map(query) do
      true -> get(base, query)
      false -> get("#{base}?q=#{query}")
    end
  end
end
