require 'rubygems'
require 'rack'

module RedSphynx
  class Server
    def call env
      req = Rack::Request.new env
      res = Rack::Response.new

      res['Content-type'] = 'text/html'
      res.write "Hello, world!"

      res.finish
    end
  end
end
