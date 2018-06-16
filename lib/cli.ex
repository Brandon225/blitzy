defmodule Blitzy.CLI do
  alias Blitzy.TasksSupervisor
  require Logger
  # require IEx

  # ./blitzy -n [requests] [url]
  def main(args) do
    Application.get_env(:blitzy, :master_node)
    |> Node.start

    Application.get_env(:blitzy, :slave_nodes)
    |> Enum.each(&Node.connect(&1))

    # IEx.pry

    # Most command line tools take in arguments and parse them like the following pipe operator.
    args
    |> parse_args
    |> process_options([node | Node.list])
  end

  defp parse_args(args) do
    OptionParser.parse(args, aliases: [n: :requests],
                              strict: [requests: :integer])
  end


  #####################
  # PRIVATE FUNCTIONS #
  #####################

  # Match:
      # 1 [requests: n] shorthand for switches --requests or -n contains a single value that is also an integer
      # 2 [url] a url
      # 3 [] no invalid arguments.  An empty list in the third element
  defp process_options(options, nodes) do
    case options do
      {[requests: n], [url], []} ->
        do_requests(n, url, nodes)
      _ ->
        do_help()
    end
  end

  defp do_requests(n_requests, url, nodes) do
    Logger.info "Pummeling #{url} with #{n_requests} requests"

    total_nodes = Enum.count(nodes)
    req_per_node = div(n_requests, total_nodes)

    nodes
    |> Enum.flat_map(fn node ->
        1..req_per_node |> Enum.map(fn _ ->
          Task.Supervisor.async({TasksSupervisor, node}, Blitzy.Worker, :start, [url])
        end)
      end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results
  end

  defp do_help do
    IO.puts """
    Usage:
    blitzy -n [requests] [url]

    Options:
    -n, [--requests] # Number of requests

    Example:
    ./blitzy -n 100 http://www.bieberfever.com
    """
    System.halt(0)
  end

  # Enum.split_with creates two lists one list with the truthy elements one with the rejects
  defp parse_results(results) do
    {successes, _failures} =
      results
        |> Enum.partition(fn x ->
          case x do
            {:ok, _} -> true
            _        -> false
          end
        end)

      total_workers = Enum.count(results)
      total_success = Enum.count(successes)
      total_failure = total_workers - total_success

      data = successes |> Enum.map(fn {:ok, time} -> time end)
      average_time = average(data)
      longest_time = Enum.max(data)
      shortest_time = Enum.min(data)

      IO.puts """
        Total workers     : #{total_workers}
        Successful reqs   : #{total_success}
        Failed res        : #{total_failure}
        Average (msecs)   : #{average_time}
        Longest (msecs)   : #{longest_time}
        Shortest (msecs)  : #{shortest_time}
      """
  end

  defp average(list) do
    sum = Enum.sum(list)
    if sum > 0, do: sum / Enum.count(list), else: 0
  end

end
