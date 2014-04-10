require "rubygems"
require "i18n"
require "rest-client"
require "hpricot"
require "cgi"
require "mongo_mapper"

require "sec_query/version"
require "sec_query/jsonable"
require "sec_query/entity"
require "sec_query/relationship"
require "sec_query/transaction"
require "sec_query/filing"
require "sec_query/sec_url"

MongoMapper.database='sec-db'
