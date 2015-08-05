# The QueryAssociationSplitter takes in a query and removes any .includes, and
# returns the new query, and an hash of association parts.
#
# Example:
#  QueryAssociationSplitter.split([['where', {name: 'Bob'}], ['includes', [:posts, [:posts, :comments], :links]]])
#    => ['where', {name: 'Bob'}], {:posts=>{:comments=>{}}, :links=>{}}]
module Volt
  class QueryAssociationSplitter
    def self.split(query)
      new_query = []
      associations = {}
      query.each do |method, *args|
        method = method.to_sym
        if method == :includes
          args.flatten(1).each do |path|
            path = [path].flatten

            node = associations
            path.each do |part|
              node = (node[part] ||= {})
            end
          end
        else
          new_query << [method, *args]
        end
      end

      return new_query, associations
    end
  end
end