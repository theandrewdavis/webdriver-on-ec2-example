# encoding: UTF-8

require 'json'
require 'headless'
require 'selenium-webdriver'

class LoginPage
	def initialize(browser)
		@browser = browser
	end

	def login_and_find_token(username, password)
		# Login using github username and password
		puts 'Logging in...'
		@browser.get('http://www.railscasts.com/login')
		login_form = @browser.find_element(:css, '#login form')
		login_form.find_element(:css, '#login_field').send_keys(username)
		login_form.find_element(:css, '#password').send_keys(password)
		login_form.submit

		# Open the first pro episode
		puts 'Finding subscription token...'
		@browser.get("http://railscasts.com/?type=pro")
		@browser.find_element(:css, '.episode h2 a').click
		Selenium::WebDriver::Wait.new.until { @browser.find_element(:css, '#episode') }

		# Return the subscription token
		@browser.find_elements(:css, '.downloads li a').find do |link|
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

	def videos
		videos = []
		current_page = 1
		loop do
			print "\rFinding #{@type} videos (page #{current_page})"
			load_page(current_page)
			videos += current_page_videos
			current_page += 1
			break if last_page?
		end
		print "\n"
		videos
	end

	private
	def current_page_videos
		@browser.find_elements(:css, '.episode h2 a').map do |page_link|
			page_link_to_video_link(page_link.attribute('href'))
		end
	end

	def page_link_to_video_link(page_link)
		name = page_link.slice(/\/([^\/]+)$/, 1)
		padded_name = name.gsub(/^\d+/) { |number| '%03d' % number }
		token_info = @type == 'free' ? 'episodes' : "subscriptions/#{@token}"
		"http://media.railscasts.com/assets/#{token_info}/videos/#{padded_name}.m4v"
	end

	def load_page(page_number)
		@browser.get("http://railscasts.com/?type=#{@type}&page=#{page_number}")
	end

	def last_page?
		@browser.find_element(:css, '.next_page.disabled') rescue false
	end
end

# Check for login info and output file
USAGE_NOTE = "ruby find_videos.rb username password"
OUTPUT_FILE = "videos.json"
abort(USAGE_NOTE) unless ARGV[0] and ARGV[1]
abort("#{OUTPUT_FILE} already exists") if File.exists?(OUTPUT_FILE)

# Start the headless browser
headless = Headless.new
headless.start
browser = Selenium::WebDriver.for(:firefox)

# Find the video links
token = LoginPage.new(browser).login_and_find_token(ARGV[0], ARGV[1])
videos = %w[pro revised free].map do |type|
	EpisodeListPage.new(browser, type, token).videos
end.flatten
File.open(OUTPUT_FILE, 'w') { |file| file.write(videos.to_json) }

# Close the browser
browser.quit
headless.destroy
