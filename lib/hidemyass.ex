defmodule Hidemyass do
  @moduledoc """
  Provides access to the free proxies indexed by HideMyAss.
  """

  @doc """
  Returns a list of all free available proxy lists.
  """
  def proxy_list do
    page_urls
    |> Enum.map(fn(page_url) -> scrape_proxies(page_url) end) 
    |> List.flatten
  end

  @doc """
  Returns a list of all the page urls for indexed proxies.
  """
  def page_urls do
    html_source = download_url("http://proxylist.hidemyass.com/")
    pages = html_source
      |> Floki.find("ul.pagination li a")
      |> Floki.attribute("href")
      |> Enum.map(fn(url) -> "http://proxylist.hidemyass.com" <> url end)

    # Append the page 1 manually.
    pages = ["http://proxylist.hidemyass.com/1" | pages]

    # Remove the duplicate last page, the "next" arrow.
    Enum.slice(pages, 0..-2)
  end

  @doc """
  Returns a list of proxies given a page url.
  """
  def scrape_proxies(page_url) do
    html_source = download_url(page_url)
    
    html_source
    |> Floki.find("table.hma-table tbody tr")
    |> Enum.map(fn(proxy_row) -> scrape_proxy_row(proxy_row) end)
  end

  @doc """
  Returns a struct of proxy information given a proxy html table row.
  """
  def scrape_proxy_row(proxy_row) do
    port = proxy_row
      |> Floki.find("td")
      |> Enum.at(2)
      |> Floki.text
      |> String.trim

    country = proxy_row
      |> Floki.find("td")
      |> Enum.at(3)
      |> Floki.text
      |> String.trim

    speed = proxy_row
      |> Floki.find("td")
      |> Enum.at(4)
      |> Floki.find("div")
      |> Floki.attribute("value") 
      |> Enum.at(0) 
      |> String.trim

    connection_time = proxy_row
      |> Floki.find("td")
      |> Enum.at(5)
      |> Floki.find("div")
      |> Floki.attribute("value") 
      |> Enum.at(0) 
      |> String.trim  

    type = proxy_row
      |> Floki.find("td")
      |> Enum.at(6)
      |> Floki.text
      |> String.trim
      
    anonimity = proxy_row
      |> Floki.find("td")
      |> Enum.at(7)
      |> Floki.text 
      |> String.trim   

    %{
      port: port,
      country: country,
      speed: speed,
      connection_time: connection_time,
      type: type,
      anonimity: anonimity
    }
  end

  defp download_url(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Error: #{url} is 404."
        nil
      {:error, %HTTPoison.Error{reason: _}} ->
        IO.puts "Error: #{url} just ain't workin."
        nil
    end
  end
end
