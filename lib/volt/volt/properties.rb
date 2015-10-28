# Volt.current_app.properties provides a hash like collection that backs to
# the database.  This is useful for storing global app property.  (A common use
# might be checking if something like an S3 bucket has been created without
# the need to make an external API request.)
class Properties
  def [](key)
    prop = Volt.current_app.store.volt_app_properties.where(name: key).first.sync

    if prop
      prop.value
    else
      nil
    end
  end

  def []=(key, value)
    unless value.is_a?(String)
      raise "property values must be a string, you passed #{value.inspect}"
    end

    Volt.current_app.store.volt_app_properties.
      update_or_create({name: key}, {value: value}).sync
  end
end
