# Sirius

A small library to coerce and validate API responses using PORO's.

## Installation

Add this line to your application's Gemfile:

    gem 'sirius'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sirius

## Usage

Sirius includes the veritable [virtus](https://github.com/solnic/virtus) and ActiveModel::Validations
libraries within classes to add attributes and validations to API response objects.

This allows validation of API reponses at a "model" level, be they responses from real-world production services or Mock API's.

Classes that include Sirius can be instantiated with either XML or JSON and can define the required attributes for that model.

## Examples

To use Sirius, simply include it in your class.  Then specify your required attributes, as in this fictitious example:

```ruby
class TwitterResponse
  include Sirius
  requires :tweet, String
  requires :date, DateTime
end
```

Then instantiate the class:

```ruby
response = TwitterResponse.new(:json, '{"tweet": "This is a tweet."}')

response.valid?
=> false

response.date = "June 22nd, 2013"
response.valid?
=> true

```
As long as the response contains the required attributes, the instance will be considered valid.

### Nested Keys

Sirius assumes that the attribute you're defining is an unnested hash key.  The following example shows how to enable nested hash keys:
```ruby
class Magician
  include Sirius
  requires :surprise, String, at: "[:black][:hat]" # or using strings "['black']['hat']" 
end
```

Then instantiate with JSON/XML as before:
```ruby
trick = '{"black": {"hat": "RABBIT!"}}'
magician = Magician.new(:json, trick)
```
And, as one might have seen coming:
```ruby
magician.surprise
=> "RABBIT!"
```
Were the black hat empty, the magician would, of course, not be valid ;)
The previous example also highlights a second hidden feature in the `at` parameter: aliasing.
If you want to refer to a JSON/XML node by a different name, simply require the attribute as you wish it to be called, pointing to its hash location.

### The Root

But what if all of your desired information is nested deeply within XML/JSON, always under the same outer node?
Because we're all lazy and efficient, Sirius offers the ability to define a root element, which serves as the jumping off point for all other attributes using `at`:

```ruby
class Treasure
  include Virtus
  attribute :type, String
  attribute :weight, Integer
  attribute :unit, String
end

class TreasureHunt
  include Sirius
  root "[:ocean][:sea_floor][:treasure_chest][:hidden_compartment]"
  requires :treasure, Treasure
end
```
So when we get back our sunken treasure response, and it contains multiple attributes we don't really care about, the code above allows us to skip straight to the good stuff!

```ruby
response = '{"ocean": 
              { "sea_floor": 
                {"treasure_chest": 
                  {"hidden_compartment": 
                    { "treasure": { "type": "Gold", "weight": 1, "unit": "Ton" }}}}}}'

treasure_hunt = TreasureHunt.new(:json, response)
treasure_hunt.treasure
=> #<Treasure:0x007fe50c98c990 @type="Gold", @weight=1, @unit="Ton">
``` 

Treasure that.

### Nested Validations
Sirius will also detect problems lurking beneath the surface by automatically searching for and validating nested attributes.
Take the previous example of a `TreasureHunt` and `Treasure` classes, this time including Sirius and requiring the presence of certain attributes.
A `TreasureHunt`, after all, is only valid if the `Treasure` it finds is:

```ruby
class TreasureHunt
  include Sirius
  root "[:ocean][:sea_floor][:treasure_chest][:hidden_compartment]"
  requires :treasure, Treasure
end

class Treasure
  include Sirius
  requires :type, String
  requires :weight, Integer
  requires :unit, String
end
```
We instantiate our `TreasureHunt` this time, however, with what appears to be a `Treasure`, but isn't:

```ruby
response = '{"ocean": 
              { "sea_floor": 
                {"treasure_chest": 
                  {"hidden_compartment": 
                    { "treasure": { "type": null, "weight": null, "unit": null}}}}}}'

treasure_hunt = TreasureHunt.new(:json, response)
treasure_hunt.treasure
```
Coercion still works, but the `Treasure` object that's been created is devoid of all value.  It is itself, of course, invalid:

```ruby
treasure_hunt.treasure.valid?
=> false
```

But since Sirius knows that our `TreasureHunt` requires a `Treasure`, our `TreasureHunt` is also rendered invalid:

```ruby
treasure_hunt.valid?
=> false
```

### The Invalid Callback
Sirius also allows an object to execute arbitrary code when the object isn't valid.  It is defined on the class and triggered when `#invalid?` is true or `#valid?` is false:

```ruby
class InvalidWithCallback
  include Sirius
  requires :important_attr, String
  requires :another, String
  when_invalid { |data, errors| puts data }
end

with_callback = InvalidWithCallback.new(:json, '{"foo":"bar"}')
with_callback.valid?
{"foo"=>"bar"}
=> false
```

As you can tell from the example above, the code will be executed by default whenever `valid?` is called before the boolean value is returned.  Should you desire a return value without executing the callback in a specific intsance, you can supply `false` to the `valid?` and `invalid?` methods:

```ruby
with_callback.valid?(false)
=> false

with_callback.invalid?(false)
=> true
```

### ActiveModel::Validations
Because Sirius uses ActiveModel::Validations under the covers, you can use most of the API you already know to validate individual attributes.
Of course, this excludes those checks relying on persistence (i.e. uniqueness) or attempts to validate an object using Virtus coercion.

```ruby
class Baz
  include Sirius
  requires :foo, String, format: { with: /bar/ }
end
```

This should play nicely with the options one normally passes to Virtus attributes, but be advised that collisions are theoretically possible.
Should you run into an issue here, please don't hesitate to open up an issue.

For further validation examples, please see the Rails [Guides](http://guides.rubyonrails.org/active_record_validations.html) or ActiveModel::Validations API docs.

## TODO

1. Pinpoint errors in JSON/XML in exception (helps to debug API problems)
2. Raise when attribute not present in data on instantiation.
3. Clearly separate ActiveModel::Validation options from those passed to Virtus 

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
