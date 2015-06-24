# A copy of the opal 0.8 promise library.  The one in 0.7.x has some bugs.

# {Promise} is used to help structure asynchronous code.
#
# It is available in the Opal standard library, and can be required in any Opal
# application:
#
#     require 'promise'
#
# ## Basic Usage
#
# Promises are created and returned as objects with the assumption that they
# will eventually be resolved or rejected, but never both. A {Promise} has
# a {#then} and {#fail} method (or one of their aliases) that can be used to
# register a block that gets called once resolved or rejected.
#
#     promise = Promise.new
#
#     promise.then {
#       puts "resolved!"
#     }.fail {
#       puts "rejected!"
#     }
#
#     # some time later
#     promise.resolve
#
#     # => "resolved!"
#
# It is important to remember that a promise can only be resolved or rejected
# once, so the block will only ever be called once (or not at all).
#
# ## Resolving Promises
#
# To resolve a promise, means to inform the {Promise} that it has succeeded
# or evaluated to a useful value. {#resolve} can be passed a value which is
# then passed into the block handler:
#
#     def get_json
#       promise = Promise.new
#
#       HTTP.get("some_url") do |req|
#         promise.resolve req.json
#       end
#
#       promise
#     end
#
#     get_json.then do |json|
#       puts "got some JSON from server"
#     end
#
# ## Rejecting Promises
#
# Promises are also designed to handle error cases, or situations where an
# outcome is not as expected. Taking the previous example, we can also pass
# a value to a {#reject} call, which passes that object to the registered
# {#fail} handler:
#
#     def get_json
#       promise = Promise.new
#
#       HTTP.get("some_url") do |req|
#         if req.ok?
#           promise.resolve req.json
#         else
#           promise.reject req
#         end
#
#       promise
#     end
#
#     get_json.then {
#       # ...
#     }.fail { |req|
#       puts "it went wrong: #{req.message}"
#     }
#
# ## Chaining Promises
#
# Promises become even more useful when chained together. Each {#then} or
# {#fail} call returns a new {Promise} which can be used to chain more and more
# handlers together.
#
#     promise.then { wait_for_something }.then { do_something_else }
#
# Rejections are propagated through the entire chain, so a "catch all" handler
# can be attached at the end of the tail:
#
#     promise.then { ... }.then { ... }.fail { ... }
#
# ## Composing Promises
#
# {Promise.when} can be used to wait for more than one promise to resolve (or
# reject). Using the previous example, we could request two different json
# requests and wait for both to finish:
#
#     Promise.when(get_json, get_json2).then |first, second|
#       puts "got two json payloads: #{first}, #{second}"
#     end
#
class Promise
  def self.value(value)
    new.resolve(value)
  end

  def self.error(value)
    new.reject(value)
  end

  def self.when(*promises)
    When.new(promises)
  end

  attr_reader :error, :prev, :next

  def initialize(action = {})
    @action = action

    @realized  = false
    @exception = false
    @value     = nil
    @error     = nil
    @delayed   = false

    @prev = nil
    @next = nil
  end

  def value
    if Promise === @value
      @value.value
    else
      @value
    end
  end

  def act?
    @action.key?(:success) || @action.key?(:always)
  end

  def action
    @action.keys
  end

  def exception?
    @exception
  end

  def realized?
    !!@realized
  end

  def resolved?
    @realized == :resolve
  end

  def rejected?
    @realized == :reject
  end

  def ^(promise)
    promise << self
    self >> promise

    promise
  end

  def <<(promise)
    @prev = promise

    self
  end

  def >>(promise)
    @next = promise

    if exception?
      promise.reject(@delayed[0])
    elsif resolved?
      promise.resolve(@delayed ? @delayed[0] : value)
    elsif rejected?
      if !@action.key?(:failure) || Promise === (@delayed ? @delayed[0] : @error)
        promise.reject(@delayed ? @delayed[0] : error)
      elsif promise.action.include?(:always)
        promise.reject(@delayed ? @delayed[0] : error)
      end
    end

    self
  end

  def resolve(value = nil)
    fail ArgumentError, 'the promise has already been realized' if realized?

    return (value << @prev) ^ self if Promise === value

    begin
      if block = @action[:success] || @action[:always]
        value = block.call(value)
      end

      resolve!(value)
    rescue Exception => e
      exception!(e)
    end

    self
  end

  def resolve!(value)
    @realized = :resolve
    @value    = value

    if @next
      @next.resolve(value)
    else
      @delayed = [value]
    end
  end

  def reject(value = nil)
    fail ArgumentError, 'the promise has already been realized' if realized?

    return (value << @prev) ^ self if Promise === value

    begin
      if block = @action[:failure] || @action[:always]
        value = block.call(value)
      end

      if @action.key?(:always)
        resolve!(value)
      else
        reject!(value)
      end
    rescue Exception => e
      exception!(e)
    end

    self
  end

  def reject!(value)
    @realized = :reject
    @error    = value

    if @next
      @next.reject(value)
    else
      @delayed = [value]
    end
  end

  def exception!(error)
    @exception = true

    reject!(error)
  end

  def then(&block)
    fail ArgumentError, 'a promise has already been chained' if @next

    self ^ Promise.new(success: block)
  end

  alias_method :do, :then

  def fail(&block)
    fail ArgumentError, 'a promise has already been chained' if @next

    self ^ Promise.new(failure: block)
  end

  alias_method :rescue, :fail
  alias_method :catch, :fail

  def always(&block)
    fail ArgumentError, 'a promise has already been chained' if @next

    self ^ Promise.new(always: block)
  end

  alias_method :finally, :always
  alias_method :ensure, :always

  def trace(depth = nil, &block)
    fail ArgumentError, 'a promise has already been chained' if @next

    self ^ Trace.new(depth, block)
  end

  def inspect
    result = "#<#{self.class}(#{object_id})"

    result += " >> #{@next.inspect}" if @next

    if realized?
      result += ": #{(@value || @error).inspect}>"
    else
      result += '>'
    end

    result
  end

  class Trace < self
    def self.it(promise)
      current = []

      current.push(promise.value) if promise.act? || promise.prev.nil?

      if prev = promise.prev
        current.concat(it(prev))
      else
        current
      end
    end

    def initialize(depth, block)
      @depth = depth

      super success: -> do
        trace = Trace.it(self).reverse
        trace.pop

        trace.shift(trace.length - depth) if depth && depth <= trace.length

        block.call(*trace)
      end
    end
  end

  class When < self
    def initialize(promises = [])
      super()

      @wait = []

      promises.each do|promise|
        wait promise
      end
    end

    def each(&block)
      fail ArgumentError, 'no block given' unless block

      self.then do|values|
        values.each(&block)
      end
    end

    def collect(&block)
      fail ArgumentError, 'no block given' unless block

      self.then do|values|
        When.new(values.map(&block))
      end
    end

    def inject(*args, &block)
      self.then do|values|
        values.reduce(*args, &block)
      end
    end

    alias_method :map, :collect

    alias_method :reduce, :inject

    def wait(promise)
      promise = Promise.value(promise) unless Promise === promise

      promise = promise.then if promise.act?

      @wait << promise

      promise.always do
        try if @next
      end

      self
    end

    alias_method :and, :wait

    def >>(*)
      super.tap do
        try
      end
    end

    def try
      if @wait.all?(&:realized?)
        if promise = @wait.find(&:rejected?)
          reject(promise.error)
        else
          resolve(@wait.map(&:value))
        end
      end
    end
  end
end
