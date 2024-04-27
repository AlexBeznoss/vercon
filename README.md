# Vercon

Vercon - a handy little gem that takes the pain out of writing tests for your Ruby projects. 🔥

The name Vercon comes from the Latin "verum conantur", meaning "they strive for truth". Vercon automatically generate test files and even though they will not always will be perfect, but at least it will save some time writting them manually.

It's build on top of Claude 3. It sends the source code of the Ruby file alongside with available factory names and current test file (in case one exists).

Claude analyzes your code to understand how it works, then uses that knowledge to put together relevant tests. 

Just let the AI handle the tedious test writing for you 🚀 

Give Vercon a try and save yourself some time and headaches when it comes to testing your Ruby apps. 

Easy, efficient, no fuss 👌

## How to use

Install the gem by executing:

    $ gem install vercon

It will require from you Claude Api Token so greb it from [here](https://console.anthropic.com/settings/keys)

Initialize the gem by executing:

    $ vercon init

Generate test:

    $ vercon generate <relative ruby file path>

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

## Contributing

Bug reports and pull requests are welcome on GitHub at [vercon repo](https://github.com/AlexBeznoss/vercon).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
