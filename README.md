# Simple websocket VCR

[![Build Status](https://travis-ci.org/Jiri-Kremser/simple-websocket-vcr.png?branch=master)](https://travis-ci.org/Jiri-Kremser/simple-websocket-vcr)
[![Coverage](https://coveralls.io/repos/github/Jiri-Kremser/simple-websocket-vcr/badge.svg?branch=master)](https://coveralls.io/github/Jiri-Kremser/simple-websocket-vcr?branch=master)
[![Code Climate](https://codeclimate.com/github/Jiri-Kremser/simple-websocket-vcr/badges/gpa.svg)](https://codeclimate.com/github/Jiri-Kremser/simple-websocket-vcr)
[![Gem Version](https://badge.fury.io/rb/simple-websocket-vcr.svg)](https://badge.fury.io/rb/simple-websocket-vcr)


Based on the idea of [vcr](https://github.com/vcr/vcr) project which record the http interactions and store them as files that can be replayed later and simulate the real communication counterpart (mostly server).

However, this projects aims on the web socket protocol where normally there is only a single HTTP connection and multiple messages or frames being sent over the channel.


### Usage

```Ruby
  it 'should record also the outgoing communication' do
    WebSocketVCR.configure do |c|
      c.hook_uris = [HOST]
    end
    WebSocketVCR.record(example, self) do
      puts 'we are recording..' if WebSocketVCR.live?
      url = "ws://#{HOST}/hawkular/command-gateway/ui/ws"
      c = WebSocket::Client::Simple.connect url do |client|
        client.on(:message, once: true, &:data)
      end
      sleep 1 if WebSocketVCR.live?
      c.send('something 1')
      c.send('something 2')
      c.send('something 3')

      expect(c).not_to be nil
      expect(c.open?).to be true
    end
  end
```

For more details consult the [specs](spec/vcr_spec.rb).