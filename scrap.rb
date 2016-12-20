require 'open-uri'
require 'nokogiri'
require 'openssl'

require_relative './common.rb'

LOGGER.info "Starting scrap.rb"

articles = DB[:articles]

title_start_regexp = /^\d+\s+/
line_start_regexp = /^\d+\.\s+/


rss_urls = [
  'https://www.buzzfeed.com/index.xml',
  'https://www.buzzfeed.com/community/justlaunched.xml',
  'https://www.buzzfeed.com/lol.xml',
  'https://www.buzzfeed.com/trashy.xml',
  'https://www.buzzfeed.com/wtf.xml'
]

rss_urls.each { | rss_url |

  LOGGER.info "Scrapping #{rss_url}"

  feed_text = open(rss_url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
  feed_doc = Nokogiri::HTML(feed_text)

  feed_doc.css('item').select{ | feed_item |

    title_el = feed_item.css('title')
    title_text = title_el.text

    title_start_regexp.match title_text

  }.each{ | feed_item |

    article_title = feed_item.css('title').text.gsub(title_start_regexp, '')

    article_guid = feed_item.css('guid').text

    article = articles.where(:guid => article_guid).first

    unless article

      article_text = open(article_guid, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
      article_doc = Nokogiri::HTML(article_text)


      article_author_meta = article_doc.css('meta[name="twitter:creator"]')

      if article_author_meta.any?
        article_author = article_author_meta.attr('content').value()
      else
        article_author = nil
      end

      article_lines = article_doc.css('.subbuzz_name').map { | article_item |
         line_text = article_item.text

         if line_start_regexp.match(line_text)
           line_text
            .gsub(line_start_regexp, '')
            .gsub(/^(a|an)\s/i, '')
            .gsub(/[\:\.\,]$/, '')
            .capitalize
         else
           nil
         end
      }.select { |article_line|
        article_line != nil
      }

      article = articles.insert(
        :guid => article_guid,
        :title => article_title.encode('utf-8'),
        :body => article_lines.join("\n").encode('utf-8'),
        :author => article_author,
        :created_at => DateTime.now
      )

      LOGGER.info "Added #{article_guid}."

    end

  }

}

LOGGER.info "Finished scrap.rb"
