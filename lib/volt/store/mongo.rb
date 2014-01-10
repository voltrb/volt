require 'mongo'

mongo_client = Mongo::MongoClient.new("localhost", 27017)

db = mongo_client.db("test1")