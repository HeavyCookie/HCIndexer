defmodule HCIndexer.Request do
  @moduledoc """
  Shorthands to `HTTPoison` methods
  """
  require Logger

  @doc """
  Return configured ElasticSearch URL. It could be defined from
  Elixir app environnement configuration :
  ```
  # config/config.exs
  config :hcindexer, elasticsearch_url: "http://elasticsearch:9200"
  ```

  Or just by system environnement variable `ELASTICSEARCH_URL`.

  Default to `http://localhost:9200`
  """
  def elasticsearch_url,
    do: Application.get_env(:hcindexer, :elasticsearch_url)
      || System.get_env("ELASTICSEARCH_URL")
      || "http://localhost:9200"

  @doc """
  Used to log internally
  """
  @spec log(atom, String.t, map | String.t) :: :ok | {:error, String.t}
  defp log(method, url, body),
    do: [ __MODULE__.__info__(:module),
      method |> Atom.to_string |> String.upcase, url, body ]
      |> Enum.join(" ")

  @doc """
  Send a request to ElasticSearch server.

  Raise an error.
  """
  @spec request!(atom, String.t, map | String.t, Keyword.t) ::
    {HTTPoison.Response.t | HTTPoison.AsyncResponse.t}
  def request!(method, url, body \\ "", opts \\ [])

  def request!(method, url, body, opts) when is_map(body) do
    request!(method, url, Poison.encode!(body), opts)
  end

  def request!(method, url, body, opts) when is_binary(body) do
    log(method, url, body)

    method
    |> HTTPoison.request!(elasticsearch_url() <> url, body,
      [{"Content-Type", "application/json"}] ++ opts)
    |> decode_response
  end

  @doc """
  Send a get request to ElasticSearch server.

  Raise an error
  """
  @spec get!(String.t, map | String.t) ::
    {HTTPoison.Response.t | HTTPoison.AsyncResponse.t}
  def get!(url, body \\ ""), do: request!(:get, url, body)

  @doc """
  Send a put request to ElasticSearch server.

  Raise an error
  """
  @spec put!(String.t, map | String.t) ::
    {HTTPoison.Response.t | HTTPoison.AsyncResponse.t}
  def put!(url, body \\ ""), do: request!(:put, url, body)

  @doc """
  Send a post request to ElasticSearch server.

  Raise an error
  """
  @spec post!(String.t, map | String.t) ::
    {HTTPoison.Response.t | HTTPoison.AsyncResponse.t}
  def post!(url, body \\ ""), do: request!(:post, url, body)

  @doc """
  Send a delete request to ElasticSearch server.

  Raise an error
  """
  @spec delete!(String.t, map | String.t) ::
    {HTTPoison.Response.t | HTTPoison.AsyncResponse.t}
  def delete!(url, body \\ ""), do: request!(:delete, url, body)

  @doc """
  Send a request to ElasticSearch server.
  """
  @spec request(atom, String.t, map | String.t, Keyword.t) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def request(method, url, body \\ "", opts \\ [])

  def request(method, url, body, opts) when is_map(body) do
    request(method, url, Poison.encode!(body), opts)
  end

  def request(method, url, body, opts) when is_binary(body) do
    log(method, url, body)

    method
    |> HTTPoison.request(elasticsearch_url() <> url, body,
      [{"Content-Type", "application/json"}] ++ opts)
    |> decode_response
  end

  defp decode_response(result) do
    case result do
      {status, response} ->
        {status, Poison.decode!(response.body)}
      _ ->
        Poison.decode!(result.body)
    end
  end

  @doc """
  Send a get request to ElasticSearch server.
  """
  @spec get(String.t, map | String.t) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def get(url, body \\ ""), do: request(:get, url, body)

  @doc """
  Send a put request to ElasticSearch server.
  """
  @spec put(String.t, map | String.t) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def put(url, body \\ ""), do: request(:put, url, body)

  @doc """
  Send a post request to ElasticSearch server.
  """
  @spec post(String.t, map | String.t) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def post(url, body \\ ""), do: request(:post, url, body)

  @doc """
  Send a delete request to ElasticSearch server.
  """
  @spec delete(String.t, map | String.t) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def delete(url, body \\ ""), do: request(:delete, url, body)
end
