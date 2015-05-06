class Tilt::Template
  # Tilt outputs the following error:
  # WARN: tilt autoloading 'sass' in a non thread-safe way; explicit require 'sass' suggested.
  # I can't get rid of this no matter what I do.  (If someone smarter wants to take a shot at
  # it, please do.)  For now for my sanity, I'm just silencing its warnings.
  def warn(*args)
    # Kernel.warn(*args)
  end
end
