require 'simple_websocket_vcr'
require 'thread'
require 'websocket-client-simple'
require 'json'

# class Object
#   alias real_sleep sleep
#
#   def sleep(*args)
#     real_sleep(*args) if !WebSocketVCR.cassette || WebSocketVCR.cassette.recording?
#   end
# end

describe 'VCR for WS' do
  HOST = 'localhost:8080'.freeze

  let(:example) do |e|
    e
  end

  let(:should_sleep) do |_|
    !WebSocketVCR.cassette || WebSocketVCR.cassette.recording?
  end

  before(:each) do
    WebSocketVCR.configuration.reset_defaults!
  end

  it 'should record the very first message caught on the client yielded by the connect method' do
    WebSocketVCR.configure do |c|
      c.hook_uris = [HOST]
    end
    WebSocketVCR.record(example, self) do
      url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
      c = WebSocket::Client::Simple.connect url do |client|
        client.on(:message, once: true, &:data)
      end
      sleep 1 if should_sleep

      expect(c).not_to be nil
      expect(c.open?).to be true
    end
  end

  it 'should record also the outgoing communication' do
    WebSocketVCR.configure do |c|
      c.hook_uris = [HOST]
    end
    WebSocketVCR.record(example, self) do
      url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
      c = WebSocket::Client::Simple.connect url do |client|
        client.on(:message, once: true, &:data)
      end
      sleep 1 if should_sleep
      c.send('something 1')
      c.send('something 2')
      c.send('something 3')

      expect(c).not_to be nil
      expect(c.open?).to be true
    end
  end

  def test_closing
    url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
    c = WebSocket::Client::Simple.connect url do |client|
      client.on(:message, once: true, &:data)
    end
    sleep 1 if should_sleep

    expect(c).not_to be nil
    expect(c.open?).to be true
    sleep 1 if should_sleep
    c.close
    expect(c.open?).to be false
  end

  it 'should record the closing event(json)' do
    WebSocketVCR.configure do |c|
      c.hook_uris = [HOST]
      c.json_cassettes = true
    end
    WebSocketVCR.record(example, self) do
      test_closing
    end
  end

  it 'should record the closing event(yaml)' do
    WebSocketVCR.configure do |c|
      c.hook_uris = [HOST]
    end
    WebSocketVCR.record(example, self) do
      test_closing
    end
  end

  def test_complex
    url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
    c = WebSocket::Client::Simple.connect url do |client|
      client.on(:message, once: true, &:data)
    end
    sleep 1 if should_sleep
    c.send('something_1')
    c.on(:message, once: true, &:data)
    sleep 1 if should_sleep

    c.send('something_2')
    c.on(:message, once: true, &:data)
    sleep 1 if should_sleep

    expect(c).not_to be nil
    expect(c.open?).to be true
    c.close
    expect(c.open?).to be false
    sleep 1 if should_sleep
  end

  it 'should record complex communications for json' do
    WebSocketVCR.configure do |c|
      c.hook_uris = [HOST]
      c.json_cassettes = true
    end
    cassette_path = '/EXPLICIT/some_explicitly_specified_json_cassette'
    WebSocketVCR.use_cassette(cassette_path) do
      test_complex
    end

    # check that everything was recorded in the json file
    file_path = "#{WebSocketVCR.configuration.cassette_library_dir}#{cassette_path}.json"
    expect(File.readlines(file_path).grep(/WelcomeResponse/).size).to eq(1)
    # once in the client message and once in the GenericErrorResponse from the server
    expect(File.readlines(file_path).grep(/something_1/).size).to eq(2)
    expect(File.readlines(file_path).grep(/something_2/).size).to eq(2)
    expect(File.readlines(file_path).grep(/close/).size).to eq(1)
  end

  it 'should record complex communications for yaml' do
    WebSocketVCR.configure do |c|
      c.hook_uris = [HOST]
    end
    cassette_path = '/EXPLICIT/some_explicitly_specified_yaml_cassette'
    WebSocketVCR.use_cassette(cassette_path) do
      test_complex
    end

    # check that everything was recorded in the yaml file
    file_path = "#{WebSocketVCR.configuration.cassette_library_dir}#{cassette_path}.yml"
    expect(File.readlines(file_path).grep(/WelcomeResponse/).size).to eq(1)
    expect(File.readlines(file_path).grep(/something_1/).size).to eq(2)
    expect(File.readlines(file_path).grep(/something_2/).size).to eq(2)
    expect(File.readlines(file_path).grep(/close/).size).to eq(1)
  end

  context 'automatically picked cassette name is ok, when using context foo' do
    it 'and example bar' do
      WebSocketVCR.record(example, self) do
        # nothing
      end
      prefix = WebSocketVCR.configuration.cassette_library_dir
      name = 'automatically_picked_cassette_name_is_ok,_when_using_context_foo_and_example_bar.yml'
      expect(File.exist?(prefix + '/VCR_for_WS/' + name)).to be true
    end
  end

  describe 'automatically picked cassette name is ok, when describing parent' do
    it 'and example child1' do
      WebSocketVCR.record(example, self) do
        # nothing
      end
      prefix = WebSocketVCR.configuration.cassette_library_dir
      name = 'automatically_picked_cassette_name_is_ok,_when_describing_parent_and_example_child1.yml'
      expect(File.exist?(prefix + '/VCR_for_WS/' + name)).to be true
    end

    it 'and example child2' do
      WebSocketVCR.record(example, self) do
        # nothing
      end
      prefix = WebSocketVCR.configuration.cassette_library_dir
      name = 'automatically_picked_cassette_name_is_ok,_when_describing_parent_and_example_child2.yml'
      expect(File.exist?(prefix + '/VCR_for_WS/' + name)).to be true
    end

    it 'and example child2 for json' do
      WebSocketVCR.configure do |c|
        c.json_cassettes = true
      end
      WebSocketVCR.record(example, self) do
        # nothing
      end
      prefix = WebSocketVCR.configuration.cassette_library_dir
      name = 'automatically_picked_cassette_name_is_ok,_when_describing_parent_and_example_child2_for_json.json'
      expect(File.exist?(prefix + '/VCR_for_WS/' + name)).to be true
    end
  end

  describe '.configuration' do
    it 'has a default cassette location configured' do
      expect(WebSocketVCR.configuration.cassette_library_dir).to eq('spec/fixtures/vcr_cassettes')
    end

    it 'has an empty list of hook ports by default' do
      expect(WebSocketVCR.configuration.hook_uris).to eq([])
    end
  end

  describe '.configure' do
    it 'configures cassette location' do
      expect do
        WebSocketVCR.configure { |c| c.cassette_library_dir = 'foo/bar' }
      end.to change { WebSocketVCR.configuration.cassette_library_dir }
        .from('spec/fixtures/vcr_cassettes')
        .to('foo/bar')
    end

    it 'configures URIs to hook' do
      expect do
        WebSocketVCR.configure { |c| c.hook_uris = ['127.0.0.1:1337'] }
      end.to change { WebSocketVCR.configuration.hook_uris }.from([]).to(['127.0.0.1:1337'])
    end

    it 'has an empty list of hook ports by default' do
      expect(WebSocketVCR.configuration.hook_uris).to eq([])
    end
  end

  context 'with cassette options' do
    it 'with :record set to :none and no cassette, it should fail' do
      prefix = WebSocketVCR.configuration.cassette_library_dir
      cassette_path = '/EXPLICIT/something_nonexistent'
      expect do
        WebSocketVCR.use_cassette(cassette_path, record: :none) do
          fail 'this code should not be reachable'
        end
      end.to raise_error(RuntimeError)
      expect(File.exist?(prefix + cassette_path + '.yml')).to be false
    end

    def test_substitution(text1, text2 = nil)
      url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
      c = WebSocket::Client::Simple.connect url do |client|
        client.on(:message, once: true) do |msg|
          expect(msg.data).to include(text1)
        end
      end
      sleep 1 if should_sleep
      text2 ||= 'something_1'
      c.send(text2)
      c.on(:message, once: true) do |msg|
        expect(msg.data).to include("Cannot deserialize: [#{text2}]")
      end
    end

    it 'with :erb set to {something: 11223344}, it should replace the variable in yaml cassette' do
      cassette_path = '/EXPLICIT/some_template'
      WebSocketVCR.configure do |c|
        c.hook_uris = [HOST]
      end
      WebSocketVCR.use_cassette(cassette_path, erb: { something: 11_223_344 }) do
        test_substitution '11223344'
      end
      file_path = "#{WebSocketVCR.configuration.cassette_library_dir}#{cassette_path}.yml"
      expect(File.readlines(file_path).grep(/<%= something %>/).size).to eq(1)
    end

    it 'with :erb set to {something: world, bar: hello}, it should replace the variables in json cassette' do
      cassette_path = '/EXPLICIT/some_template'
      WebSocketVCR.configure do |c|
        c.hook_uris = [HOST]
        c.json_cassettes = true
      end
      WebSocketVCR.use_cassette(cassette_path, erb: { something: 'world', bar: 'hello' }) do
        test_substitution 'world', 'hello'
      end
    end
  end
end
