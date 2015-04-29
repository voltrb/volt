require 'volt/data_stores/base'
require 'mongo'

module Volt
  class DataStore
    class MongoDriver < Base
      attr_reader :db, :mongo_db

      def initialize
        if Volt.config.db_uri.present?
          @mongo_db ||= Mongo::MongoClient.from_uri(Volt.config.db_uri)
          @db ||= @mongo_db.db(Volt.config.db_uri.split('/').last || Volt.config.db_name)
        else
          @mongo_db ||= Mongo::MongoClient.new(Volt.config.db_host, Volt.config.db_path)
          @db ||= @mongo_db.db(Volt.config.db_name)
        end
      end

      def insert(collection, values)
        @db[collection].insert(values)
      end

      def update(collection, values)
        # TODO: Seems mongo is dumb and doesn't let you upsert with custom id's
        begin
          @db[collection].insert(values)
        rescue Mongo::OperationFailure => error
          # Really mongo client?
          if error.message[/^11000[:]/]
            # Update because the id already exists
            update_values = values.dup
            id = update_values.delete(:_id)
            @db[collection].update({ _id: id }, update_values)
          else
            return { error: error.message }
          end
        end

        return nil
      end

      def query(collection, query)
        allowed_methods = ['find', 'skip', 'limit']

        cursor = @db[collection]

        query.each do |query_part|
          method_name, *args = query_part

          unless allowed_methods.include?(method_name.to_s)
            raise "`#{method_name}` is not part of a valid query"
          end

          cursor = cursor.send(method_name, *args)
        end

        cursor.to_a
      end

      def delete(collection, query)
        @db[collection].remove(query)
      end

      def drop_database
        db.connection.drop_database(Volt.config.db_name)
      end
    end
  end
end
