require 'volt/utils/logging/task_argument_filterer'

module Volt
  class TaskLogger
    def self.task_dispatch_message(logger, args)
      msg = "task #{logger.class_name}##{logger.method_name} in #{logger.run_time}\n"
      if args.size > 0
        arg_str = TaskArgumentFilterer.filter(args).map(&:inspect).join(', ')
        msg += "with args: #{arg_str}\n"
      end
      msg
    end
  end
end
