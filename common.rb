require 'dotenv'
Dotenv.load

require 'logger'
require 'sequel'
require 'twitter'

LOGGER = Logger.new($stdout)

CONFIG = {
    :database_filepath => ENV['DATABASE_FILEPATH'] || 'database.sqlite3',
    :wkhtmltoimage_bin =>  ENV['WKHTMLTOIMAGE_BIN'] || 'wkhtmltoimage',
    :twitter_consumer_key => ENV['TWITTER_CONSUMER_KEY'],
    :twitter_consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
    :twitter_access_token => ENV['TWITTER_ACCESS_TOKEN'],
    :twitter_access_token_secret => ENV['TWITTER_ACCESS_TOKEN_SECRET']
}

DB = Sequel.sqlite(CONFIG[:database_filepath])

if ENV['ENVIRONMENT'] == 'development'
  DB.loggers << LOGGER
end

DB.create_table? :articles do
  primary_key :id
  String :guid, :unique => true, :null => false
  String :author
  String :title
  String :body
  String :tweet_id
  DateTime :created_at
  DateTime :tweeted_at
end

TWITTER = Twitter::REST::Client.new do |config|
  config.consumer_key        = CONFIG[:twitter_consumer_key]
  config.consumer_secret     = CONFIG[:twitter_consumer_secret]
  config.access_token        = CONFIG[:twitter_access_token]
  config.access_token_secret = CONFIG[:twitter_access_token_secret]
end
