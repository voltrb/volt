require 'mongo'

class DataStore
  def initialize
    @@mongo_db ||= Mongo::MongoClient.new("localhost", 27017)
    @@db ||= @@mongo_db.db("development")
  end
  
  def query(collection, query)
    @@db[collection].find(query).to_a
  end
end