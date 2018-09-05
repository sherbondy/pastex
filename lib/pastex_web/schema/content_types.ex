defmodule PastexWeb.Schema.ContentTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias PastexWeb.ContentResolver

  # async resolution... so we can execute queries concurrently...
  import Absinthe.Resolution.Helpers, only: [async: 1]

  # Note that Notation deliberately does not give us query, mutation, and subscription
  # to avoid multiple conflicting defs for top-level objects...

  # Relay gives us limit, cursors, etc. for FREEEEEE
  # introduces new `connection` concept, nice mapping directly from Ecto...
  # Relay.Connection.from_query...

  def get_author(%{author_id: nil}, _, _) do
    {:ok, nil}
  end

  def get_author(%{author_id: id} = paste, _, _) do
    # SHAZAM, now getting user is async!!!

    async(fn ->
      {:ok, Pastex.Identity.get_user(paste.author_id)}
    end)
    |> IO.inspect()
  end

  # THIRD POSSIBLE RETURN TUPLE: {:middleware, ...}
  # execution is handed off to e.g. async middelware to get the actual final return value...
  # Refer to `Absinthe.Middelware.Async` to examine how to write your own middleware that mucks
  # with resolution


  # Custom object type
  @desc "This is the description for blob(s) of pasted code. Note this is a @desc, not a @doc"
  object :paste do
    # type wrapper... cannot be null... promise to user...
    # id type serializes id as string... might be a uuid etc...
    # might be like stripe "card_bla2341", "Paste:12"...
    # Relay pagination takes advantage of id type...
    # Could make a custom scalar to parse your specific e.g. uuid type to display helpful error messages on parse...
    field :id, non_null(:id)
    field :name, non_null(:string)

    field :author, :user do
      complexity 100

      # Anonymous function with multiple cases...
      resolve &get_author/3
    end

    field :visibility, :string

    field :excited_name, non_null(:string) do
      resolve(fn parent, _, _ ->
        {:ok, String.upcase(parent.name)}
      end)
    end

    field :description, :string
    # composes... will always be a list, but may be empty...
    # Absinthe 1.4 uses macros to define...
    # but in 1.5 can use SDL... big block-o-text... matches JS setup...
    # easy interop of spec with JS people using SDL...
    # user-defined :file type...
    @desc "A paste can contain multiple files..."
    # Fields can have resolvers directly in objects too!
    field :files, non_null(list_of(:file)) do
      resolve &ContentResolver.get_files/3
    end
  end

  # built-in types are not special... we could use exclusively custom types in schema...
  # may want to tag a scalar even if it maps to a primitive type...
  # absinthe ships with convenient custom types e.g. for datetime

  object :file do
    field :name, :string do
      resolve(fn file, _, _ ->
        {:ok, file.name || "Untitled File"}
      end)
    end

    # Descriptions can also be explicitly passed as key-value pairs...
    field :body, :string do
      arg :style, :body_style
      resolve &ContentResolver.format_body/3
    end
    # note how file refers back to paste... two-way edge relationship...
  end

  # Yay enum types...

  enum :body_style do
    value :formatted
    value :original
  end


  connection(node_type: :paste)


  object :content_queries do
    connection field :pastes, node_type: :paste do
      # Hooray compexlity analysis!!!

      complexity fn args, child_complexity ->
        trunc((1 + args[:first] * 0.1) * child_complexity)
      end

      resolve &ContentResolver.list_pastes/3
    end
  end


  object :content_mutations do
    field :create_paste, :paste do
      arg :input, non_null(:create_paste_input)
      resolve &ContentResolver.create_paste/3
    end
  end

  # Best way to compose *create* and *update* operations so things are reusable?
  # You can actually *import_fields* ... like inheritance... so can have a set of shared fields...

  # input objects are purely structural...
  # why distinguish from regular objects? input objects are *A*-CYCLIC. No cycles...
  # does not make conceptual sense... Kind of like an ecto changeset...
  # More ergonomic to group all required inputs for creation than having separate args for each input...
  # Also, sometimes mutation contents are distinct from actual fields on the resulting object...
  input_object :create_paste_input do
    field :name, non_null(:string)
    field :description, :string
    # files can't be null, and the list can't be null
    field :visibility, :string
    field :files, non_null(list_of(non_null(:file_input)))
  end

  input_object :file_input do
    field :name, :string
    field :body, :string
  end

end
