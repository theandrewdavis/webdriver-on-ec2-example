# encoding: UTF-8

require 'json'
require 'headless'
require 'selenium-webdriver'

def wait_for(&block)
	Selenium::WebDriver::Wait.new.until { block.call }
end

class LoginPage
	def initialize(browser)
		@browser = browser
	end

	def login!(username, password)
		puts 'Logging in...'
		@browser.get('http://www.railscasts.com/login')
		login_form = @browser.find_element(:css, '#login form')
		login_form.find_element(:css, '#login_field').send_keys(username)
		login_form.find_element(:css, '#password').send_keys(password)
		login_form.submit
	end
end

class SubscriptionTokenPage
	def initialize(browser)
		@browser = browser
	end

	def find_token
		puts 'Finding subscription token...'

		# Go to the first pro episode
		@browser.get("http://railscasts.com/?type=pro")
		@browser.find_element(:css, '.episode h2 a').click
		Selenium::WebDriver::Wait.new.until { @browser.find_element(:css, '#episode') }

		# Find subscription token
		token = @browser.find_elements(:css, '.downloads li a').find do |link|
			link.text == 'm4v'
		end.attribute('href').slice(/subscriptions\/(\w+)\/videos/, 1)
	end
end

class EpisodeListPage
	def initialize(browser, type, token)
		@browser = browser
		@type = type
		@token = token
		@current_page = 1
	end

	def all_links
		links = []
		loop do
			next_page
			links += current_page_video_links
			break if last_page?
		end
		links
	end

	def current_page_video_links
		@browser.find_elements(:css, '.episode h2 a').map do |link|
			title = link.attribute('href').slice(/\/([^\/]+)$/, 1)
			title.gsub!(/^\d+/) { |number| '%03d' % number }
			title_to_video_link(title)
		end
	end

	def title_to_video_link(title)
		if @type == 'pro' || @type == 'revised'
			"http://media.railscasts.com/assets/subscriptions/#{@token}/videos/#{title}.m4v"
		else
			"http://media.railscasts.com/assets/episodes/videos/#{title}.m4v"
		end
	end

	def next_page
		@browser.get("http://railscasts.com/?type=#{@type}&page=#{@current_page}")
		print "\rFinding #{@type} videos (page #{@current_page})"
		print "\n" if last_page?
		@current_page += 1
	end

	def last_page?
		@browser.find_element(:css, '.next_page.disabled') rescue false
	end
end

headless = Headless.new
headless.start
browser = Selenium::WebDriver.for(:firefox)

login_info = JSON.parse(File.open('login.json').read)
LoginPage.new(browser).login!(login_info['username'], login_info['password'])
token = SubscriptionTokenPage.new(browser).find_token
videos = ['pro', 'revised'].map do |type|
	EpisodeListPage.new(browser, type, token).all_links
end.flatten
File.open('videos.json', 'w') { |file| file.write(videos.to_json) }

browser.quit
headless.destroy
