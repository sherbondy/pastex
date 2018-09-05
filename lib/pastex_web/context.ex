defmodule PastexWeb.Context do
  @moduledoc false

  alias Pastex.Identity

  def init(opts), do: opts

  def call(conn, _opts) do
    # Yay, we are finally using the third argument for resolvers!!! The context!!!
    context =  build_context(conn)

    # Library places metadata in the conn __private__ field for convenience...
    # GraphQL stuff will look up this in the conn and use it for auth...

    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
    # With is awesome, like if-let in lisp with multiple things being assigned...
    # If any of the with fails to match, falls back to the else clause... avoid handling
    # all of the failure cases separately... lets you code to the *happy path* with single
    # failure outcome...

    # Verify token is valid AND that it still matches a legitimate user in the DB...

    # Cowboy and plug downcase headers for consistent string matching...

    # %{} = user is a pattern match to validate that it is actually a struct, thus a user, rather than e.g. nil

    # We could include all sorts of http-related things like our IP address and make them query-able...
    # Building the context is kind of our bridge between http connection concerns and our more pure query concerns...

    with ["Bearer " <> token] <- Plug.Conn.get_req_header(conn, "authorization"),
         {:ok, user_id} <- PastexWeb.Auth.verify(token),
         %Identity.User{} = user <- Identity.get_user(user_id) do
      %{current_user: user}
    else
      _ ->
        IO.puts("no user found...")
        %{}
    end
  end

end
