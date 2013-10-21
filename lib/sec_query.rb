require "rubygems"
require "i18n"
require "rest-client"
require "hpricot"
require "mongo_mapper"

require "sec_query/version"
require "sec_query/jsonable"
require "sec_query/entity"
require "sec_query/relationship"
require "sec_query/transaction"
require "sec_query/filing"

MongoMapper.database='sec-db'
