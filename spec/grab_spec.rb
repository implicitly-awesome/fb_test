require 'spec_helper'

describe ImageGrabber do

  let(:provider_name) { 'faraday' }
  let(:url) { 'www.google.com' }
  let(:src) { '/test.png' }
  let(:dir) { './tmp' }

  before(:all) {
    @page = "<html><body><img src='test_src' /img></body></html>"
  }

  describe ImageGrabber::ProviderFabric do
    subject { ImageGrabber::ProviderFabric }

    it 'should has .get_for method' do
      expect(subject.respond_to?(:get_for)).to be_truthy
    end

    context 'should return a provider' do
      it 'should return any provider' do
        expect(subject.get_for(url)).not_to be_nil
      end

      context 'called with :provider_name attribute' do
        it "should return Faraday provider with :provider_name => 'faraday'" do
          expect(subject.get_for(url, 'faraday')).to be_an_instance_of Faraday::Connection
        end
      end

      context 'called without :provider_name attribute' do
        it 'should return Faraday provider as default' do
          expect(subject.get_for(url)).to be_an_instance_of Faraday::Connection
        end
      end
    end
  end

  describe ImageGrabber::DocumentFetcherFabric do
    subject { ImageGrabber::DocumentFetcherFabric }

    it 'should has .get_fetcher method' do
      expect(subject.respond_to?(:get_fetcher)).to be_truthy
    end

    it 'should return DocumentFetcher instance' do
      expect(subject.get_fetcher(url, provider_name)).to be_an_instance_of ImageGrabber::DocumentFetcher
    end
  end

  describe ImageGrabber::DocumentFetcher do
    subject { ImageGrabber::DocumentFetcher }

    it 'should has #get method' do
      expect(subject.new.respond_to?(:get)).to be_truthy
    end

    it 'has a #provider property' do
      expect(subject.new.respond_to?(:provider)).to be_truthy
      expect(subject.new.provider).not_to be_nil
    end

    context '#get' do
      before do
        @response = instance_double(Faraday::Response)
        @provider = instance_double(Faraday::Connection)
      end

      it 'should return html page' do
        allow(@response).to receive(:body).and_return @page
        allow(@provider).to receive(:get).and_return @response

        expect(subject.new(url, @provider).get).not_to be_nil
        expect(subject.new(url, @provider).get).to eq(@page)
      end
    end
  end

  describe ImageGrabber::PercentagePrinter do
    subject { ImageGrabber::PercentagePrinter }

    let(:count) { 100 }

    it 'should has #next method' do
      expect(subject.new(count).respond_to?(:next)).to be_truthy
    end

    it 'should echo count after initializing' do
      expect(STDOUT).to receive(:puts).once.with("Total: #{count} items were found")
      subject.new(count)
    end

    context '#next' do
      it 'should return next %' do
        pp = subject.new(count)
        expect(pp.next).to eq(2)
      end
    end
  end

  describe ImageGrabber::Grabber do
    subject { ImageGrabber::Grabber }

    before do
      @doc_fetcher_fabric = double(ImageGrabber::DocumentFetcherFabric)
      @doc_fetcher = double(ImageGrabber::DocumentFetcher)
      @doc_parser = double(ImageGrabber::DocumentParser)
      allow(@doc_fetcher).to receive(:async).and_return @page
      allow(@doc_fetcher).to receive(:get).and_return @page
      allow(@doc_fetcher_fabric).to receive(:get_fetcher).and_return @doc_fetcher
      allow(@doc_parser).to receive(:get_images).and_return %w(<img src='test_src'/> <img src='test_src2'/>)
      @grabber = subject.new(@doc_fetcher_fabric, @doc_parser)
    end

    after do
      FileUtils.rm_rf(dir)
    end

    it 'should has #grab method' do
      expect(subject.new.respond_to?(:grab)).to be_truthy
    end

    it 'should has #save_image_file method' do
      expect(subject.new.respond_to?(:save_image_file)).to be_truthy
    end

    context '#save_image_file' do
      it 'should take :url, :src, :dir args' do
        expect { @grabber.save_image_file }.to raise_error ArgumentError
        expect { @grabber.save_image_file(url, src, dir) }.not_to raise_error ArgumentError
      end

      it 'should get image by :url+:src if :src is relative' do
        expect(@doc_fetcher_fabric).to receive(:get_fetcher).with(url+src, provider_name)
        expect(@doc_fetcher).to receive(:get)
        @grabber.save_image_file(url, src, dir)
      end

      it 'should get image by :src if its absolute' do
        src = 'http://www.google.com/test.png'
        expect(@doc_fetcher_fabric).to receive(:get_fetcher).with(src, provider_name)
        expect(@doc_fetcher).to receive(:get)
        @grabber.save_image_file(url, src, dir)
      end

      it 'creates directory by :dir argument if that directory doesnt exist' do
        FileUtils.rm_rf(dir)
        @grabber.save_image_file(url, src, dir)
        expect(Dir.exists?(dir)).to be_truthy
      end

      it 'makes a file (image) from response & saves it in directory' do
        FileUtils.rm_rf(dir)
        expect(File).not_to exist(dir+src)
        @grabber.save_image_file(url, src, dir)
        expect(File).to exist(dir+src)
      end
    end

    context '#grab' do
      it 'should take :url & :dir args' do
        expect { @grabber.grab }.to raise_error ArgumentError
        expect { @grabber.grab(url, dir) }.not_to raise_error ArgumentError
      end

      it 'should add to :url http:// if that part doesnt exist' do
        url = 'www.google.com'
        expect(@doc_fetcher_fabric).to receive(:get_fetcher).with('http://'+url, provider_name)
        @grabber.grab(url, dir)
      end

      it 'should get html page' do
        expect(@doc_fetcher_fabric).to receive(:get_fetcher)
        expect(@doc_fetcher).to receive(:get)
        @grabber.grab(url, dir)
      end

      it 'should get images array from html page' do
        expect(@doc_parser).to receive(:get_images).once
        @grabber.grab(url, dir)
      end

      it 'should try to save file [images_array].count times' do
        expect(@grabber).to receive(:save_image_file).exactly(2).times
        @grabber.grab(url, dir)
      end
    end
  end

end