class ChangeAuthorIdOfComments < ActiveRecord::Migration
  def change
    change_column "comments", "author_id", "bigint"
  end
end
