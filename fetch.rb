# encoding: UTF-8

require 'headless'
require 'watir-webdriver'

headless = Headless.new
headless.start
browser = Watir::Browser.start 'www.google.com'
puts browser.title
browser.close
headless.destroy
