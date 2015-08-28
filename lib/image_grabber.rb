require 'faraday'
require 'nokogiri'
require 'benchmark'
require 'celluloid/current'

#=========================================================================
# In order to implement reliable tests and implement maintainable solution
# I've uses some SOLID principles:
# - dependencies injection/inversion
# - open-closed principle
# - single responsibility
# Async requests were implemented with Celluloid
#=========================================================================

module ImageGrabber

  # provider fabric exists in order to have a possibility to be open for modification
  class ProviderFabric
    def self.get_for(url, provider_name='faraday')
      case provider_name
        when 'faraday' then Faraday.new(url: url)
        else
          Faraday.new(url: url)
      end
    end
  end

  # represents an html-document downloaded by url
  class DocumentFetcher
    include Celluloid

    attr_reader :url, :provider

    def initialize(url='/', provider=ProviderFabric.get_for(url))
      @url = url
      @provider = provider
    end

    # get methods on various providers can distinguish
    def get
      case provider.class
        when Faraday::Connection then provider.get.body
        else
          provider.get.body
      end
    rescue => e
      puts e.message
      nil
    end
  end

  class DocumentFetcherFabric
    def self.get_fetcher(url, provider_name)
      DocumentFetcher.new(url, ProviderFabric.get_for(url, provider_name))
    end
  end

  # prints progress in percents
  class PercentagePrinter
    attr_accessor :count, :current

    def initialize(count)
      @count = count
      @current = 1
      puts "Total: #{count} items were found"
    end

    def next
      print "[#{@current*100/@count}%]\r"
      @current += 1
    end
  end

  class DocumentParser
    def self.get_images
      raise 'You should provide implementation in descendant class'
    end
  end

  class NokogiriParser < DocumentParser
    # parse html into Nokogiri object and select all <img> tags on the page
    def self.get_images(html)
      Nokogiri::HTML(html).css('img')
    end
  end

  class Grabber
    attr_reader :fetcher_fabric, :parser

    # inject a dependency in order to decouple document fetching mechanism and Grabber
    def initialize(fetcher_fabric=DocumentFetcherFabric, parser=NokogiriParser)
      @fetcher_fabric = fetcher_fabric
      @parser = parser
    end

    # the main method
    def grab(url, dir)
      # wrap in output
      print_output {
        # if target doesnt have http:// suffix - add it
        url = 'http://'+url unless url =~ /\Ahttp/
        # try to get an html-document by url
        doc = fetcher_fabric.get_fetcher(url, 'faraday').get
        if doc
          images = parser.get_images(doc)
          pp = PercentagePrinter.new images.count
          # for each image - try to fetch and save a file
          images.each do |img|
            # print process in percents
            pp.next
            begin
              # make async requests (the last 'true' param)
              if img['src']
                save_image_file url, img['src'], dir, true
              elsif img['data-src']
                save_image_file url, img['data-src'], dir, true
              else
                next
              end
            rescue => e
              puts e.message
              next
            end
          end
        else
          puts 'Document is empty!'
        end
      }
    end

    # output printings wrapper
    def print_output
      puts '--Start--'
      time = Benchmark.measure {
        yield if block_given?
      }
      puts "\nIt takes: #{time.real.round(1)} secs"
      puts '--End--'
    end

    # download & save file
    def save_image_file(url, src, dir, async=false)
      # get a file name from src attribute
      file_name = src.split('/').last
      # if src attribute presented as relative path - attach it to url of a page in order to make it absolute
      src = url + src unless src =~ /\Ahttp/
      # create directory if it doesnt exist
      Dir.mkdir(dir) unless File.directory?(dir)
      doc = nil
      begin
        # try to get a file as html-document (html-response)
        doc = async ? fetcher_fabric.get_fetcher(src, 'faraday').async.get : fetcher_fabric.get_fetcher(src, 'faraday').get
      rescue => e
        raise 'Error occurred during file downloading: '+e.message
      end
      # if doc exists - save it to a file with proper file name in target directory
      File.open(File.join(dir, file_name), 'w+') { |f| f.write doc } if doc
    rescue => e
      raise 'Error occurred during file saving: '+e.message
    end
  end

end