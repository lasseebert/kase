# Kase

Kase gracefully handles `[status, result]`-like return values from methods.

It is a tool to avoid using exceptions as flow control and to write safer and
more readable code.

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

Kase is a module that is meant to be included where you want to use it. The
module is just a bunch of helper methods, so if you don't like to include
stuff in your classes, you can use the Kase::Switcher class instead, in which
the logic is implemented.

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

For an example of this, see the example in the beginning of this README.

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
