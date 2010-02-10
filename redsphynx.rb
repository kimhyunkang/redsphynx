require 'rubygems'
require 'rack'
require 'yaml'
require 'maruku'
require 'erubis'

module RedSphynx
  ServerDefaultOption = {
    template_dir: "templates",
    article_dir: "articles"
  }

  class Article
    attr_reader :meta, :content
    def initialize filename
      meta, content = File.read(filename).split("\n\n", 2)
      @meta = YAML.load(meta)
      @content = Maruku.new(content).to_html
    end
  end

  class Server
    def initialize option = {}
      @option = ServerDefaultOption
      @option.update option
    end

    def call env
      req = Rack::Request.new env
      res = Rack::Response.new

      res['Content-type'] = 'text/html'
      @article = Article.new("#{@option[:article_dir]}/#{req.path_info}.txt")
      res.write @article.content

      res.finish
    end
  end
end
