defmodule HCIndexer.Request do
  alias HCIndexer.Results

  require Logger

  def elasticsearch_url, do: Application.get_env(:hcindexer, :elasticsearch_url)

  def log(method, url, body),
    do: [ __MODULE__.__info__(:module),
      method |> Atom.to_string |> String.upcase, url, body ]
      |> Enum.join(" ")

  def request!(method, url, body \\ "", opts \\ [])

  def request!(method, url, body, opts) do
    request!(method, url, Poison.encode!(body), opts)
  end

  def request!(method, url, body, opts) when is_binary(body) do
    log(method, url, body)

    method
    |> HTTPoison.request!(elasticsearch_url <> url, body,
      [{"Content-Type", "application/json"}] ++ opts)
    |> decode_response
  end

  def get!(url, body \\ ""), do: request!(:get, url, body)
  def put!(url, body \\ ""), do: request!(:put, url, body)
  def post!(url, body \\ ""), do: request!(:post, url, body)

  def request(method, url, body \\ "", opts \\ [])

  def request(method, url, body, opts) when is_map(body) do
    request(method, url, Poison.encode!(body), opts)
  end

  def request(method, url, body, opts) when is_binary(body) do
    log(method, url, body)

    method
    |> HTTPoison.request(elasticsearch_url <> url, body,
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

  def get(url, body \\ ""), do: request(:get, url, body)
  def put(url, body \\ ""), do: request(:put, url, body)
  def post(url, body \\ ""), do: request(:post, url, body)

  def search(index, q) do
    base_url = "#{index}/_search"
    results = case is_binary(q) do
      true -> get!("#{base_url}?q=#{q}")
      false -> get!(base_url, q)
    end
    Results.parse(results)
  end
end
