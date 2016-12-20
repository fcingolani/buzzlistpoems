require 'pp'
require 'erb'

require_relative './common.rb'

articles = DB[:articles]

LOGGER.info "Starting tweet.rb"

article = articles.first(:tweeted_at => nil)

if article == nil
  LOGGER.info("No article to tweet")
  exit
end

html = ERB.new(<<-BLOCK).result(binding)
<html>
  <head>
    <meta charset="UTF-8" /><link href="https://fonts.googleapis.com/css?family=Droid+Serif" rel="stylesheet">
		<style>
			html {
				font-family: 'Droid Serif', serif;
        font-size: 1.2em;
        color: #333;
        background: #EEE;
        padding: 1em;
        -webkit-font-smoothing: antialiased;
			}
		</style>
  </head>
  <body>
    <!--<h1><%= article[:title] %></h1>-->
    <div><%= article[:body].gsub("\n", "<br/>\n") %></div>
  </body>
</html>
BLOCK

html_filename = "#{article[:id]}.html"
html_filepath = File.expand_path html_filename

png_filename = "#{article[:id]}.png"
png_filepath = File.expand_path png_filename

File.open(html_filepath, 'w') { |file|
  file.write html
  file.close
  system(CONFIG[:wkhtmltoimage_bin], "--width", "600", html_filepath, png_filepath)
}



File.open(png_filepath, 'r') { |file|

  tweet_text = ""

  # tweet_text = "#{article[:title]}"

  # if article[:author]
  #   tweet_text += " by #{article[:author]}666"
  # end

  tweet_text += " #{article[:guid]}"

  tweet = TWITTER.update_with_media(tweet_text, file)
  article[:tweet_id] = tweet.id
  
}

File.delete(html_filepath, png_filepath)

article[:tweeted_at] = DateTime.now

articles
  .where(:guid => article[:guid])
  .update(article)

LOGGER.info("Tweeted #{article[:guid]}")
