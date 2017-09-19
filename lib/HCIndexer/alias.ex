defmodule HCIndexer.Alias do
  @moduledoc """
  Manage ElasticSearch aliases
  """
  import HCIndexer.Request

  @doc """
  List indexes of provided alias
  """
  @spec list_index(String.t) :: list
  def list_index(name) do
    case get("#{name}/_aliases") do
      {:error, _} ->
        []
      {:ok, result} ->
        Map.keys(result)
    end
  end

  @doc """
  Remove all alias for provided index
  """
  @spec delete_all(String.t) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def delete_all(name) do
    actions = name
      |> list_index()
      |> Enum.map(&(%{"remove" => %{"index" => &1, "alias" => name}}))

    post "_aliases", %{"actions" => actions}
  end
end
