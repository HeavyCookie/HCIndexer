defmodule HCIndexer.Request do
  alias HCIndexer.Results

  require Logger

  def request(method, url, body \\ "", opts \\ [])

  def request(method, url, body, opts) when is_map(body) do
    Logger.debug "#{__MODULE__.__info__(:module)} " <>
      "#{method |> Atom.to_string |> String.upcase} " <>
      "#{url}\n #{inspect(body, pretty: true)}"
    request(method, url, Poison.encode!(body), opts)
  end

  def request(method, url, body, opts) when is_binary(body) do
    elasticsearch_url = Application.get_env(:hcindexer, :elasticsearch_url)
    Logger.debug "#{__MODULE__.__info__(:module)} " <>
      "#{method |> Atom.to_string |> String.upcase} " <>
      "#{url}\n #{body}"

    method
    |> HTTPoison.request!(
      elasticsearch_url <> url,
      body,
      [{"Content-Type", "application/json"}] ++ opts
    )
    |> case do
      response = %{status_code: code} when code in 400..499 ->
        error_body = response.body |> Poison.decode!
        Logger.error( error_body |> inspect(pretty: true))
        {:err, response}
      response -> response
    end
  end

  def get(url, body \\ ""), do: request(:get, url, body)
  def put(url, body \\ ""), do: request(:put, url, body)
  def post(url, body \\ ""), do: request(:post, url, body)

  def search(index, q) do
    base_url = "#{index}/_search"
    results = case is_binary(q) do
      true -> get("#{base_url}?q=#{q}")
      false -> get(base_url, q)
    end
    Results.parse(results)
  end
end