defmodule PastexWeb.Schema.IdentityTypes do
  use Absinthe.Schema.Notation
  alias Pastex.Identity

  def create_session(_, %{email: email, password: password}, _) do
    case Identity.authenticate(email, password) do
      {:ok, user} ->
        session = %{
          user: user,
          token: PastexWeb.Auth.sign(user.id)
        }

        {:ok, session}

      error ->
        error
    end
  end

  object :identity_queries do
    field :me, :user do
      resolve(fn(_, _, %{context: context}) ->
        # HOORAY CONTEXT: Third argument is the "resolution struct" which includes AST, Schema,
        # LOTS of data... the one valuable thing we usually grab is the context for global concerns like auth...
        # Context is a large map with lots of info...
        # We usually pattern match out the specific thing we want to grab...
        {:ok, context[:current_user]}
      end)
    end
  end


  object :identity_mutations do
    field :create_session, :session do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve &create_session/3
    end
  end

  object :session do
    field :user, non_null(:user)
    field :token, non_null(:string)
  end


  # Note, you could return a keyword list or map with message: key and other assorted metadata
  # so your errors are more machine-readable...
  # Could have middleware handle ecto errors nicely... Kronky ecto errors to Absinthe errors solution.

  # Absinthe.Resolution.project(resolution)
  # project gives you flattened resolved fields...
  # Peek into child queries and pre-fetch...
  # But now we have DataLoader, so that is probably a better option for query optimization...

  # How can we consolidate our auth business logic & resolver logic via MIDDLEWARE?
  # Let's do it!

  # Fields have meta with key-value information that you can use ...
  # DataLoader and batching to avoid excessive queries...

  object :user do
    field :name, non_null(:string)
    # Resolver on email to determine whether we should display it based on whether the user
    # is the current user... only show them their own email for their own documents...
    field :email, :string, meta: [auth: :use_nil]
  end

  # formerly had a complicated auth resolver for email, now replaced logic by PastexWeb.Middleware.Auth
  # resolve macro IS a middleware!!!
  # `resolve` = middleware Absinthe.Resolution, your_resolve_fn

end
