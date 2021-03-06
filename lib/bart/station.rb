# http://api.bart.gov/docs/etd/etd.aspx uses abbr and abbreviation
# interchangeably. I'm settling on abbr to be both clear and concise.

require 'nokogiri'
require 'bart/utils'

# CLEANUP
require 'net/http'
require 'bart/estimate'

module Bart
  class Station
    attr_reader :api_key, :stations, :load_first, :name_lookup

    # Used this instead of attr_writer so we can do cleanup when the abbr changes...
    def abbr=(x)
      @abbr = x ? x.to_s.upcase : nil
      @_departures = nil
    end

    def abbr
      @abbr
    end

    # This is used for debugging
    attr_reader :document

    def initialize(options = {})
      @abbr       = options[:abbr]       ? options[:abbr].to_s.upcase : nil

      @api_key    = options[:api_key]    ? options[:api_key]    : 'MW9S-E7SL-26DU-VV8V'
      @stations   = options[:stations]   ? options[:stations]   : nil
      @load_first = options[:load_first] ? options[:load_first] : true

      @stations = load_stations_if_not_loaded if (!@stations and load_first)
    end

    def station_set?
      return false if @abbr.nil?
      true
    end

    def name
      load_stations_if_not_loaded
      @name_lookup ||= stations.inject({}) { |memo, i| memo[i[:abbr]] = i[:name]; memo }
      @name_lookup[@abbr]
    end

    def departures
      @_departures ||= load_departures
    end

    # fetch
    def load_departures
      fail("You must set the station before loading departures!") unless station_set?
      params = {
        cmd: 'etd',
        orig: @abbr,
        key: @api_key
      }

      response = Bart::Utils.ask_bart(params)

      Bart::Utils.parse_departures(response.body)
    end

    def load_stations_if_not_loaded
      @stations ||= load_stations
    end

    def load_stations
      params = {
        :cmd => 'stns',
        :key => @api_key
      }

      response = Bart::Utils.ask_bart(params)
      Bart::Utils.parse_stations(response.body)
    end
  end
end
