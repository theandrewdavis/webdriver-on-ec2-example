A Ruby script to scrape links to videos from [Railscasts](http://railscasts.com/).

### Why? ###

I love [WebDriver](http://seleniumhq.org/). I've used it at [Appian](http://www.appian.com/) to write automated browser-based regression tests and to [scrape photos from Facebook](https://github.com/theandrewdavis/fb-photo-backup). I've recently been developing on an [Amazon EC2](http://aws.amazon.com/ec2/) instance, so when I stumbled upon an [article](http://watirmelon.com/2011/08/27/running-headless-watir-webdriver-tests-using-a-real-browser/) about running WebDriver with [headless](https://github.com/leonid-shevtsov/headless), I wanted to try it out.

In preparation for a trip, I wrote a script to scrape videos from Railscasts using a headless browser on my EC2 instance. What follows is a run-down of that process.

### Setting up WebDriver on EC2  ###

Open the [EC2 Dashboard](console.aws.amazon.com/ec2/) and lanch a new Ubuntu instance. SSH into the new instance with

```
ssh -i privatekey.pem ubuntu@instanceaddress.amazonaws.com
```

and install the dependencies ([xvfb](http://en.wikipedia.org/wiki/Xvfb), [Firefox](http://www.mozilla.org/en-US/firefox/new/), build tools, [rvm](https://rvm.io/), headless, and [webdriver-selenium](http://selenium.googlecode.com/svn/trunk/docs/api/rb/index.html)) with

```
sudo apt-get update
sudo apt-get install xvfb firefox build-essential
sudo curl -L https://get.rvm.io | sudo bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
rvmsudo gem install --no-ri --no-rdoc headless selenium-webdriver
```

Now you can run WebDriver from Ruby. An example follows

```ruby
require 'headless'
require 'selenium-webdriver'

# Start the headless browser
headless = Headless.new
headless.start
browser = Selenium::WebDriver.for(:firefox)

# Print google.com's title
browser.get('http://google.com')
puts browser.title

# Close the browser
browser.quit
headless.destroy
```

### Scraping Railscasts ###

You can run my Railscast scraping code with

```
curl -L https://github.com/theandrewdavis/webdriver-on-ec2-example/tarball/master | tar -xz
cd theandrewdavis-webdriver-on-ec2-example-*
ruby find_videos.rb railscasts_username railscasts_password
```

The resulting file, `videos.json` will contain links to all Railscasts videos. You can then copy the link file to your local machine and download the episodes by running

```
ruby downloader.rb videos.json target_folder
```

It will skip already-downloaded files so you can use it to only download new episodes.