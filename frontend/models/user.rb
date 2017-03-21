class User
  include DataMapper::Resource
  include BCrypt

  property :id,       Serial,     key: true, unique: true
  property :name,     String,     unique: true
  property :password, BCryptHash

end
