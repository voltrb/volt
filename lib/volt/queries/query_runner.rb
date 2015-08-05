# The QueryRunner takes in a query and runs the query and any subqueries
# needed to return the full results for an end users query.  .includes will be
# parsed out (using QueryAssociationSplitter).
#
# When #run is called, it returns an Array of Hashes with the associations
# filled in.

require 'volt/queries/query_association_splitter'

module Volt
  class QueryRunner
    def initialize(data_store, collection, query)
      @data_store = data_store

      @collection = collection
      # query and associations are immutable
      @query, @associations = QueryAssociationSplitter.split(query)
    end

    # Runs the query and
    def run
      # When running through the query, run subqueries for any associations

      # First run the root query
      data = @data_store.query(@collection, @query)

      parent_model = Volt::Model.class_at_path([@collection])

      run_associations(data, parent_model, @associations)

      data
    end

    # @param - the data hash for the root node
    # @param - the path where the assocation data should be matched
    # @param - a hash with the parts for the association
    def run_associations(data, parent_model, associations)
      associations.each_pair do |assoc, sub_assocs|
        run_association(data, parent_model, assoc, sub_assocs)
      end
    end

    def run_association(data, parent_model, assoc, sub_assocs)
      assoc = assoc.to_sym
      # Make another query to load in the association's data
      # .where(post_id: parent_ids)
      assoc_data = parent_model.associations[assoc.to_sym]

      unless assoc_data
        raise "`#{assoc}` was used in .includes(..), but is not a valid association"
      end

      foreign_key, local_key, collection = assoc_data.mfetch(
        :foreign_key, :local_key, :collection
      )

      # Lookup the local_key from the association on the models
      parent_ids = ids(data, local_key)

      subquery = [[:where, {foreign_key => parent_ids}]]
      results = @data_store.query(collection, subquery)

      # For to many associations, we map to an array by id
      results_by_assoc_id = if assoc_data[:to_many]
        id_map_array(results, foreign_key)
      else
        id_map(results, foreign_key)
      end

      # Insert data into the original results
      data.each do |row|
        # Assign a field on the row for the child data
        row[assoc] = results_by_assoc_id[row[local_key]]
      end

      # unless sub_associations == {}
      #   # There are more associations off of this one

      # end
    end


    private

    # returns an array of ids
    def ids(data, map_by=:id)
      data.map {|v| v[map_by]}
    end

    # Takes in an array of hashes, and returns a hash of hashes keyed by id
    def id_map(data, map_by=:id)
      data.map {|v| [v[map_by], v] }.to_h
    end

    # like id_map, except it returns an array for multiple maps to the same id
    def id_map_array(data, map_by=:id)
      results = {}
      data.each do |row|
        key = row[map_by]
        results[key] ||= []
        results[key] << row
      end

      results
    end

  end
end