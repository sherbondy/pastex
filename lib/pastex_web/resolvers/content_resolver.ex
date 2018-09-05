defmodule PastexWeb.ContentResolver do
  alias Pastex.Content

  ### QUERIES

  # Naming scheme more akin to phoenix controllers... less hierarchical naming...
  # ContentResolver does not really belong to something called Resolvers...
  # Reinforce idea that resolvers are functionally very analogous to controllers...

  def list_pastes(_, _, %{context: context}) do
    current_user = context[:current_user]
    IO.puts("Executing pastes...")
    {:ok, Content.list_pastes(current_user)}
  end

  # Yay, actually using args...
  # paste = parent in this case....
  # get_files will get called once for each paste... we need to be careful about n+1 query problem...
  # can do batching up-front...
  def get_files(paste, _args, _resolution) do
    IO.puts("Executing get files...")
    IO.inspect(paste)

    # @TODO: refactor so this is not causing n+1 query issue...
    # Should be leveraging business logic from content module...
    files =
      paste
      |> Ecto.assoc(:files)
      |> Pastex.Repo.all()

    IO.inspect(files)

    {:ok, files}
  end

  def format_body(file, arguments, _) do
    # Atom keys = known to your program... Use string keys when input comes from world...
    # because atoms cannot be garbage collected, an adversarial user could e.g. keep handing you
    # unique keys until you run out of memory...

    case arguments do
      %{style: :formatted} ->
        {:ok, Code.format_string!(file.body)}
      _ ->
        {:ok, file.body}
    end
  end


  ### MUTATIONS


  # A mutation! A new kind of thing...
  def create_paste(_, %{input: input} = arguments, %{context: context}) do
    IO.inspect(arguments)

    input =
      case context do
        %{current_user: %{id: id}} ->
          Map.put(input, :author_id, id)
        _ ->
          input
      end

    case Content.create_paste(input) do
      {:ok, paste} ->
        {:ok, paste}
      {:error, _} ->
        # @TODO: add nicer errors...
        {:error, "didn't work..."}
    end
  end

end
