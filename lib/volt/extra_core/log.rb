if RUBY_PLATFORM == 'opal'
  require 'volt/extra_core/logger'
else
  require 'logger'
end

# Simple global access to the logger.
# You can also include Log into a class to get the logger
# inside of it.
module Log
  def self.logger
    @logger = Logger.new(STDOUT)
  end

  # Module methods, Log.info...
  def self.fatal(*args, &block)
    logger.fatal(*args, &block)
  end

  def self.info(*args, &block)
    logger.info(*args, &block)
  end

  def self.warn(*args, &block)
    logger.warn(*args, &block)
  end

  def self.debug(*args, &block)
    logger.debug(*args, &block)
  end

  def self.error(*args, &block)
    logger.error(*args, &block)
  end

  # Included methods, info "something"
  def fatal(*args, &block)
    Log.fatal(*args, &block)
  end

  def info(*args, &block)
    Log.info(*args, &block)
  end

  def warn(*args, &block)
    Log.warn(*args, &block)
  end

  def debug(*args, &block)
    Log.debug(*args, &block)
  end

  def error(*args, &block)
    Log.error(*args, &block)
  end
end
