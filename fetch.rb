# encoding: UTF-8

require 'json'
require 'headless'
require 'selenium-webdriver'

headless = Headless.new
headless.start

def wait_for(&block)
	Selenium::WebDriver::Wait.new.until { block.call }
end

def screenshot(buffer, filename)
	buffer.take_screenshot "/home/ubuntu/railscast-links/screenshots/#{filename}.jpg"
end

def normal_episode_link(title)
	"http://media.railscasts.com/assets/episodes/videos/#{title}.m4v"
end

def pro_episode_link(title, token)
	"http://media.railscasts.com/assets/subscriptions/#{token}/videos/#{title}.m4v"
end

browser = Selenium::WebDriver.for(:firefox)
browser.get('http://www.railscasts.com/login')

# Login
login_info = JSON.parse(File.open('login.json').read)
login_form = browser.find_element(:css, '#login form')
login_form.find_element(:css, '#login_field').send_keys(login_info['username'])
login_form.find_element(:css, '#password').send_keys(login_info['password'])
login_form.submit

# Go to the first pro episode
browser.get("http://railscasts.com/?type=pro")
browser.find_element(:css, '.episode h2 a').click
wait_for { browser.find_element(:css, '#episode') }

# Find subscription token
token = browser.find_elements(:css, '.downloads li a').find do |link|
	link.text == 'mp4'
end.attribute('href').slice(/subscriptions\/(\w+)\/videos/, 1)

# Find all episodes on the first page of the 'Pro Episodes' section
browser.get("http://railscasts.com/?type=pro")
browser.find_elements(:css, '.episode h2 a').each do |link|
	title = link.attribute('href').slice(/\/([^\/]+)$/, 1)
	puts pro_episode_link(title, token)
end

browser.quit
headless.destroy
