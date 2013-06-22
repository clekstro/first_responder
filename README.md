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

This allows validation of API reponses at a "model" level,
be they responses from real-world production services or Mock API's.

Classes that include Sirius can be instantiated with either XML or JSON and can define the required attributes for that model.

Using Virtus, those attributes can be coerced to primitive or custom object types.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
