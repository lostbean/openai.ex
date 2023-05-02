defmodule OpenAI.Client do
  @moduledoc false
  alias OpenAI.Config
  use HTTPoison.Base

  def process_response_body(body) do
    try do
      {status, res} = Jason.decode(body)

      case status do
        :ok ->
          {:ok, res}

        :error ->
          body
      end
    rescue
      _ ->
        body
    end
  end

  def handle_response(httpoison_response) do
    case httpoison_response do
      {:ok, %HTTPoison.Response{status_code: 200, body: {:ok, body}}} ->
        res =
          body
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Map.new()

        {:ok, res}

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{body: {:ok, body}}} ->
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def add_organization_header(headers, config) do
    org_key = config.organization_key || Config.org_key()
    if org_key do
      [{"OpenAI-Organization", org_key} | headers]
    else
      headers
    end
  end

  def add_azure_header(headers, config) do
    api_key = config.api_key || Config.api_key()
    azure_deployment_id = config.azure_deployment_id || Config.azure_deployment_id()
    if azure_deployment_id && api_key do
      [{"api-key", api_key} | headers]
    else
      headers
    end
  end

  def add_azure_query_params(params, config) do
    api_version = config.azure_api_version || Config.azure_api_version()
    azure_deployment_id = config.azure_deployment_id || Config.azure_deployment_id()
    if azure_deployment_id && api_version do
      params ++ [{"api-version", api_version} | params]
    else
      params
    end
  end

  def resolve_url(url, config) do
    base_url = config.api_url || Config.api_url()
    azure_deployment_id = config.azure_deployment_id || Config.azure_deployment_id()

    if azure_deployment_id do
      "#{base_url}/deployments/#{azure_deployment_id}/#{url}"
    else
      "#{base_url}/v1/#{url}"
    end
  end

  def request_headers(config) do
    [
      bearer(config),
      {"Content-type", "application/json"}
    ]
    |> add_organization_header(config)
    |> add_azure_header(config)
  end

  def bearer(config), do: {"Authorization", "Bearer #{config.api_key || Config.api_key()}"}

  def request_options(config) do
    opts = config.http_options || Config.http_options

    has_params = fn
      {:params, _} -> true
      _            -> false
    end

    append_params = fn
      {:params, previous} -> {:params, add_azure_query_params(previous, config)}
      x -> x
    end

    if Enum.find(opts, has_params) do
      Enum.map(opts, append_params)
    else
      opts ++ [{:params, add_azure_query_params([], config)}]
    end
  end

  def request_query_params(config) do
    []
    |> add_azure_query_params(config)
  end

  def api_get(url, config) do
    url
    |> resolve_url(config)
    |> get(request_headers(config), request_options(config))
    |> handle_response()
  end

  def api_post(url, params \\ [], config) do
    body =
      params
      |> Enum.into(%{})
      |> Jason.encode!()

    url
    |> resolve_url(config)
    |> post(body, request_headers(config), request_options(config))
    |> handle_response()
  end

  def multipart_api_post(url, file_path, file_param, params, config) do
    body_params = params |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)

    body = {
      :multipart,
      [
        {:file, file_path,
         {"form-data", [{:name, file_param}, {:filename, Path.basename(file_path)}]}, []}
      ] ++ body_params
    }

    url
    |> resolve_url(config)
    |> post(body, request_headers(config), request_options(config))
    |> handle_response()
  end

  def api_delete(url, config) do
    url
    |> resolve_url(config)
    |> delete(request_headers(config), request_options(config))
    |> handle_response()
  end
end
