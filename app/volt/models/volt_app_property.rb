# VoltAppProperty backs the volt_app.properties hash.  properties is designed
# to allow things like gems that have external setup processes (creating an
# S3 bucket for example) to keep track of if that action has been completed on
# a global level.
class VoltAppProperty < Volt::Model
  field :name, String
  field :value, String
end
