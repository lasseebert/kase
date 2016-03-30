# Kase

Kase gracefully handles `[status, result]`-like return values from methods.

It is a tool to avoid using exceptions as flow control and to write safer and
more readable code.

[![Gem Version](https://badge.fury.io/rb/kase.svg)](https://badge.fury.io/rb/kase)
[![Build Status](https://travis-ci.org/lasseebert/kase.svg?branch=master)](https://travis-ci.org/lasseebert/kase)

## Introduction

The idea is inspired by Elixir in which many functions returns something like
`{:ok, result}` or `{:error, :not_found, "More specific error message"}`.

In Ruby we would usually handle those kind of return values like this:

```ruby
class Orders
  def process(cart)
    status, result, message = complete_order(cart)

    case status
    when :ok
      order = result
      process_order(order)
    when :error
      error_kind = result
      case error_kind
      when :not_found
        [404, {}, "Not found"]
      when :invalid_state
        [400, {}, "Invalid request: #{message}"]
      else
        raise "Unhandled error kind: #{error_kind}"
      end
    else
      raise "Unhandles status: #{status}"
    end
  end
end
```

This is hard to read.

Furthermore, the two lines that raises exception on unhandled status and
error_kind are probably getting zero code coverage (otherwise we would have
handled that specific status or error_kind).

With Kase we can do this instead, which is equivalent to the above:

```ruby
require "kase"

class Orders
  include Kase

  def process(cart)
    kase complete_order(cart) do
      on :ok do |order|
        process_order(order)
      end

      on :error, :not_found do
        [404, {}, "Not found"]
      end

      on :error, :invalid_state do |message|
        [400, {}, "Invalid request: #{message}"]
      end
    end
  end
end
```

This is much more easy to read and reason about.

See below for more a full list of what Kase does.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "kase", "~> 0.1"
```

## Usage


### kase

`kase` is the method used to match an array of values (typically a
`[status, result]`-like array) against a number of "patterns" using the
`on`-method. A pattern in this sense is just some values matching the array from
the beginning using `==`.

E.g. the pattern `:a, :b` matches `[:a, :b]` and `[:a, :b, :c]`, but not
`[:c, :a, :b]`.

The block in the first pattern that matches will be executed, and the return
value from that block is the return value of `kase`.

If no patterns match, a `Kase::NoMatchError` is raised.

An empty pattern will match everything, so that can be used as a catch-all.

The values yielded to the block are all the values that is not part of the
pattern. E.g. if `[:ok, "THE RESULT"]` is matched with `on(:ok, &block)`,
`"THE RESULT"` is yielded to block.

#### Simple examples:

```ruby
kase process_order do
  on :ok do
    puts "Great success!"
  end

  on :error do
    puts "BOOM"
  end
end
```

This will output "Great success" if process_order returns `:ok`,
`[:ok]` or `[:ok, some, more, values, here]`.

It will output "BOOM" if process_order returns `:error`, `[:error]` or
`[:error, some, more, values]`

If process_order returns something that is not matched, e.g. `:not_found`, this
will raise a `Kase::NoMatchError`.

#### Using the values

In the above example we don't use the values returned by process_order, if more
than one value is returned.

All values that are not part of the pattern will be yielded to the given block:

```ruby
kase process_order do
  on :ok do |order|
    puts "Great success: #{order.inspect}"
  end

  on :error do |reason, message|
    puts "BOOM! #{reason}: #{message}"
  end
end
```

Notice that we don't have to return the same number of values for each case to
be able to catch and use the values.

#### Matching on multiple values

We can match on multiple values, but only from the left:

```ruby
kase process_order do
  on :ok do |order|
    puts "Great success: #{order.inspect}"
  end

  on :error, :not_found do
    puts "Not found!"
  end

  on :error, :invalid_record do |message|
    puts "Invalid record: #{message}"
  end
end
```

This `kase` will handle `[:ok, order]`, `[:error, :not_found]` and
`[:error, :invalid_record, "Message"]`, but will raise a `Kase::NoMatchError` on
e.g. `[:error, :not_authorized]`

### ok!

Sometimes we only expect the `:ok` status to appear. In that case we can use
`ok!` as a shorthand.

It can rewrite this:

```ruby
kase something do
  on :ok do |result|
    handle_result(result)
  end
end
```

To this:

```ruby
ok! something do |result|
  handle_result(result)
end
```

### Include or module_function

Kase is a module with helper methods. You can either include it in your own
class or use the methods as module functions. So both of these will work:

```ruby
require "kase"

class MyFirstClass
  include Kase

  def call
    kase some_result do
      ...
    end
  end
end

class MySecondClass
  def call
    Kase.kase some_result do
      ...
    end
  end
end
```

All the logic resides in the Kase::Switcher class which you can use directly if
you need to:

```ruby
switcher = Kase::Switcher.new(:ok, "RESULT")
switcher.on(:ok) { |result| puts result }
switcher.on(:error) { |message| warn message }
switcher.validate!
result = switcher.result
```

The above is equivalent to:

```ruby
result = Kase.kase :ok, "RESULT" do
  on(:ok) { |result| puts result }
  on(:error) { |message| warn message }
end
```

Note that `#kase` is aliased to `#call` so you can use the shorthand
`Kase.(values)`.

## Development

* Install dependencies with `bundle`
* Run specs with `bundle exec rspec`

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/lasseebert/kase.

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

### Pull requests

To make a pull request:

1. Fork the project
2. Make at least one failing test that proves the bug or describes the feature.
3. Implement bugfix or feature
4. Make pull request

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
