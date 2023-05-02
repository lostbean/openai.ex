defmodule OpenAI.Completions do
  @moduledoc false
  alias OpenAI.Client
  alias OpenAI.Config

  @base_url "/completions"
  @engines_base_url "/engines"

  def url(), do: @base_url
  def deprecated_url(engine_id), do: "#{@engines_base_url}/#{engine_id}/completions"

  def fetch(params, config \\ %Config{}) do
    url()
    |> Client.api_post(params, config)
  end

  def fetch_by_engine(engine_id, params, config \\ %Config{}) do
    deprecated_url(engine_id)
    |> Client.api_post(params, config)
  end
end
