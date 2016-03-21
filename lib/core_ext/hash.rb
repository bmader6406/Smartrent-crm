class Hash
  def nest(keys)
    keys.reduce(self) {|m,k| m && m[k] }
  end
end
