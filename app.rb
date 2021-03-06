# Dependencies
require 'sinatra'
require 'sinatra/activerecord'
require 'sprockets'
require 'sprockets-helpers'
require 'uglifier'
require 'sass'
require 'json'
require 'uri'
require 'httparty'
require 'fileutils'

# Require all the things, models, helpers, controller
Dir.glob('app/{models,helpers,controllers}/*.rb').each {|file| require_relative file }

# Main app
class App < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :sprockets, Sprockets::Environment.new(root)
  set :assets_prefix, '/assets'
  set :digest_assets, false
  set :static, true
  set :public_folder, 'public'
  set :views, 'views'
  set :show_exceptions, false
  #set :method_override, true # when using post for put / delete etc...
  set :session_secret, 'Super awesome random session string'
  enable :sessions

  # Setup Sprockets
  configure do
    sprockets.append_path File.join(root, 'assets', 'stylesheets')
    sprockets.append_path File.join(root, 'assets', 'javascripts')
    sprockets.append_path File.join(root, 'assets', 'images')

    # Configure Sprockets::Helpers (if necessary)
    Sprockets::Helpers.configure do |config|
      config.environment = sprockets
      config.prefix      = assets_prefix
      config.digest      = digest_assets
      config.digest      = digest_assets
      config.public_path = public_folder

      # Force to debug mode in development mode
      # Debug mode automatically sets
      # expand = true, digest = false, manifest = false
      config.debug       = true if development?
    end

    # Some application settings, probably doing this wrong, but the controller extends from Sinatra,
    # so I am not able to access the settings
    Config.base_url = 'http://eu.battle.net/heroes/en/heroes/'
    Config.hero_base_url = 'http://eu.battle.net/heroes/en/heroes/%s/'
    Config.local_file = File.dirname(__FILE__) + '/data/heroes.json'
    Config.local_hero_folder = File.dirname(__FILE__) + '/data/heroes'
    Config.local_detail_file = File.dirname(__FILE__) + '/data/heroes_detail.json'
    Config.hero_local_file = File.dirname(__FILE__) + '/data/heroes/%s.json'
    Config.image_urls = {
      'bust' => 'http://media.blizzard.com/heroes/%s/bust.jpg',
      'trait' => 'http://media.blizzard.com/heroes/%s/abilities/icons/%s.png'
    }

    Config.set('image_path', '/images/')
    Config.set('hero_image_pre', {
        'greymane' => 'greymane/',
        'valeera' => 'standard/',
        'varian' => 'warrior/',
        'chogall' => 'cho/',
    })

    ActiveSupport::Inflector.inflections do |inflect|
      inflect.irregular 'hero', 'heroes'
    end
  end

  configure :production do
    Config.local_file_cache_time = 86400.0
  end

  # compress assets
  sprockets.js_compressor  = :uglify
  sprockets.css_compressor = :scss

  get "/assets/*" do
    env["PATH_INFO"].sub!("/assets", "")
    settings.sprockets.call(env)
  end

  # Controllers
  use ApplicationController
  use AdminController
  use DraftController

  error do
    puts env['sinatra.error'].inspect
    #render_error 500, _('Internal Server Error'), env['sinatra.error'].message
  end

  error Sinatra::NotFound do
    content_type 'text/plain'
    [404, 'Not Found son']
  end
end