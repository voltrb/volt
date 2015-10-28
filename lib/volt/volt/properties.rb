# Volt.current_app.properties provides a hash like collection that backs to
# the database.  This is useful for storing global app property.  (A common use
# might be checking if something like an S3 bucket has been created without
# the need to make an external API request.)
class Properties
  def [](key)

  end

  def []=(key, value)
    prop = Volt.current_app.store.volt_app_properties.where({name: key}).first_or_create.sync
  end
end
