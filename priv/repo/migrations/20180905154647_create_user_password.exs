defmodule Pastex.Repo.Migrations.CreateUserPassword do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:password, :text, null: false)
    end
  end
end
