require 'rubygems'
require 'rack'
require 'erubis'
require 'yaml'
require 'maruku'
require 'digest'

module RedSphynx
  ServerDefaultOption = {
    template_dir: "templates",
    article_dir: "articles"
  }

  module Template
    def render filename, option = {}, &blk
      template = ERB.new(File.read(filename))
      if option[:ctx]
        template.result(option[:ctx].get_binding &blk)
      else
        template.result(binding)
      end
    end
  end

  class Article
    attr_accessor :meta, :content
    def self.load filename
      article = Article.new
      meta, content = File.read(filename).split("\n\n", 2)
      article.meta = YAML.load(meta)
      article.content = Maruku.new(content).to_html
      article
    rescue Errno::ENOENT
      nil
    end
  end

  class RenderContext
    def initialize(hash = {})
      @hash = hash
    end

    def get_binding &blk
      binding
    end

    def method_missing m, *args, &blk
      @hash[m]
    end
  end

  class Server
    include Template

    def initialize option = {}
      @option = ServerDefaultOption
      @option.update option
    end

    def call env
      req = Rack::Request.new env
      res = Rack::Response.new

      res['Content-type'] = 'text/html'
      @article = Article.load("#{@option[:article_dir]}/#{req.path_info}.txt")

      if @article
        title = @article.meta[:title]
      else
        title = "404"
      end

      ctx = RenderContext.new(:title => title, :css => "/css/main.css")
      body = render("#{@option[:template_dir]}/layout.html.erb", :ctx => ctx) do
        if @article
          @article.content
        else
          "404: article not found"
        end
      end

      res.write body
      res['Etag'] = Digest::SHA1.hexdigest(body)

      res.finish
    end
  end
end
