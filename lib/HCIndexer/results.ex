defmodule HCIndexer.Results do
  defstruct [:original, :results]

  def parse(%HTTPoison.Response{} = response) do
    %HCIndexer.Results{
      original: response,
      results: (response.body |> Poison.decode!)["hits"]["hits"],
    }
  end
end
