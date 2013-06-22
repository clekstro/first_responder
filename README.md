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

## TODO

1. Custom Attributes: have methods defined on the class that do not directly map to their corresponding hash key.
2. Nested Attributes: have methods defined on the class that map to nested hash keys, exposing them as first class methods.
3. Raise when attribute not present in data on instantiation.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
