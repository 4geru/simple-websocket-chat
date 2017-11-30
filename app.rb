require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require 'sinatra-websocket'
require './model.rb'
require 'json'

set :server, 'thin'
set :sockets, []
set :counts, []

before do
  if Count.all.size == 0
    Count.create(count: 0)
  end
end

get '/' do
  @count = Count.first.count
  erb :index
end

get '/websocket/chat' do
  if request.websocket? then
    request.websocket do |ws|
      ws.onopen do
        c = Count.first
        c.count = c.count + 1
        c.save
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        settings.sockets.each do |s|
          s.send(JSON.unparse({:msg => msg}))
        end
      end
      ws.onclose do
        c = Count.first
        c.count = c.count - 1
        c.save
        settings.sockets.delete(ws)
      end
    end
  end
end

get '/websocket/count' do
  if request.websocket? then
    request.websocket do |ws|
      ws.onopen do settings.counts << ws end
      ws.onmessage do |msg|
        settings.counts.each do |s|
          s.send(Count.first.count.to_s)
        end
      end
      ws.onclose do settings.counts.delete(ws) end
    end
  end
end