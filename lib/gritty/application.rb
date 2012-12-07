require 'methadone'
require 'gritty/rugged'
require 'gritty/core'

module Gritty
    class NoFileError < Exception; end

    class Application
        include Methadone::CLILogging

        DEFAULT_GRITFILES = [ 'Gritfile', 'gritfile', 'Gritfile.rb', 'gritfile.rb' ]
        DEFAULT_OPTIONS = { }

        def initialize(options, *args)
        end

        def run
        end

    end

    class << self
        def application
            @application ||= Gritty::Application.new(Hash.new)
        end

        def application=(app)
            @application = app
        end

        def run!
            extend(Methadone::Main)
            extend(Methadone::CLILogging)

            main do |*filters|
                Gritty.application = Gritty::Application.new options, *filters
                Gritty.application.run
            end
            arg :filters, :any

            go!
        end
    end
end
