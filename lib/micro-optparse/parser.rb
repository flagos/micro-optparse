require 'ostruct'
require 'optparse'

class Parser
  attr_accessor :banner, :version

  def initialize
    @options = []
    @used_short = []
    yield self
  end

  def option(name, desc, settings = {})
    @options << [name, desc, settings]
  end

  def short_from(name)
    name.to_s.chars.each do |c|
      next if @used_short.include?(c)
      return c # returns from short_from method
    end
  end

  def validate(options) # remove this method if you want fewer lines of code and don't need validations
    options.each_pair do |key, value|
      opt = nil
      @options.each { |o| opt = o if o[0] == key }
      unless opt[2][:value_in_set].nil? || opt[2][:value_in_set].include?(value)
        puts "Parameter for " << key.to_s << " must be in [" << opt[2][:value_in_set].join(",") << "]" ; exit(1)
      end
      unless opt[2][:value_matches].nil? || opt[2][:value_matches] =~ value
        puts "Parameter must match /" << opt[2][:value_matches].source << "/" ; exit(1)
      end
      unless opt[2][:value_satisfies].nil? || opt[2][:value_satisfies].call(value)
        puts "Parameter must satisfy given conditions (see description)" ; exit(1)
      end
    end
  end

  def process!
    options = {}
    optionparser = OptionParser.new do |p|
      @options.each do |o|
        @used_short << short = o[2][:short] || short_from(o[0])
        options[o[0]] = o[2][:default] || false # set default
        klass = o[2][:default].class == Fixnum ? Integer : o[2][:default].class

        if klass == TrueClass || klass == FalseClass || klass == NilClass # boolean switch
          p.on("-" << short, "--[no-]" << o[0].to_s.gsub("_", "-"), o[1]) {|x| options[o[0]] = x}
        else # argument with parameter
          p.on("-" << short, "--" << o[0].to_s.gsub("_", "-") << " " << o[2][:default].to_s, klass, o[1]) {|x| options[o[0]] = x}
        end
      end

      p.banner = @banner unless @banner.nil?
      p.on_tail("-h", "--help", "Show this message") {puts p ; exit}
      short = @used_short.include?("v") ? "-V" : "-v"
      p.on_tail(short, "--version", "Print version") {puts @version ; exit} unless @version.nil?
    end

    begin
      optionparser.parse!(ARGV)
    rescue OptionParser::ParseError => e
      puts e.message ; exit(1)
    end

    validate(options) if self.respond_to?("validate")
    options
  end
end