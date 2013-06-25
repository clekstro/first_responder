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
  requires :rabbit, String, at: "['black']['hat']"
end
```
Then instantiate with JSON/XML as before:
```ruby
trick = '{"black": {"hat": "Surprise!"}}'
magician = Magician.new(:json, trick)
```
And, as one might have seen coming:
```ruby
magician.rabbit
=> "Surprise!"
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
  root "['ocean']['sea_floor']['treasure_chest']['hidden_compartment']"
  requires :treasure, Treasure
end
```
So when we get back our sunken treasure response, and it contains multiple attributes we don't really care about, the code above allows us to skip straight to the good stuff!

```ruby
response = '{"ocean": { "sea_floor": {"treasure_chest": {"hidden_compartment": { "treasure": { "type": "Gold", "weight": 1, "unit": "Ton" }}}}}}'
treasure_hunt = TreasureHunt.new(:json, response)
treasure_hunt.treasure
=> #<Treasure:0x007fe50c98c990 @type="Gold", @weight=1, @unit="Ton">
``` 

Treasure that.

## TODO

1. Allow for nested object validation.  As Virtus can coerce to custom objects, require that all nested objects are themselves valid.
2. Pinpoint errors in JSON/XML in exception (helps to debug API problems)
3. Raise when attribute not present in data on instantiation.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
