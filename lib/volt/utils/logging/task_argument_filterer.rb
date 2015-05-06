# TaskArgumentFilterer will recursively walk any arguemnts to a task and filter any
# hashes with a filtered key.  By default only :password is filtered, but you can add
# more with Volt.config.filter_keys
class TaskArgumentFilterer
  def self.filter(args)
    new(args).run
  end

  def initialize(args)
    # # Cache the filter args
    @@filter_args ||= begin
      # Load, with default, convert to symbols
      arg_names = (Volt.config.filter_keys || [:password]).map(&:to_sym)
    end

    @args = args
  end

  def run
    filter_args(@args)
  end

  private

  def filter_args(args)
    if args.is_a?(Array)
      args.map { |v| filter_args(v) }
    elsif args.is_a?(Hash)
      args.map do |k, v|
        if @@filter_args.include?(k.to_sym)
          # filter
          [k, '[FILTERED]']
        else
          # retunr unfiltered
          [k, filter_args(v)]
        end
      end.to_h # <= convert back to hash
    else
      return args
    end
  end
end
