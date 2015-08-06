class ActiveVoltInstance < Volt::Model
  field :server_id, String
  field :ips, String
  field :port, Fixnum
  field :time#, Time
end