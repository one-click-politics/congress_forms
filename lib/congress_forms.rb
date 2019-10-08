require "yaml"

require "capybara"
require "webdrivers/chromedriver"
require "selenium/webdriver"

require "webdrivers"

require "congress_forms/version"

require "cwc"

unless ENV["CWC_API_KEY"].nil?
  Cwc::Client.configure(
    api_key: ENV["CWC_API_KEY"],
    host: ENV["CWC_HOST"],
    delivery_agent: ENV["CWC_DELIVERY_AGENT"],
    delivery_agent_ack_email: ENV["CWC_DELIVERY_AGENT_ACK_EMAIL"],
    delivery_agent_contact_name: ENV["CWC_DELIVERY_AGENT_CONTACT_NAME"],
    delivery_agent_contact_email: ENV["CWC_DELIVERY_AGENT_CONTACT_EMAIL"],
    delivery_agent_contact_phone: ENV["CWC_DELIVERY_AGENT_CONTACT_PHONE"]
  )
end

# ENV['HEADLESS'] = '0'

Capybara.register_driver :chrome do
  Capybara::Selenium::Driver.new(nil, browser: :chrome)
end

Capybara.register_driver :remote do
  Capybara::Selenium::Driver.new(
    nil,
    browser: :remote,
    url: ENV["WEBDRIVER_HOST"],
    desired_capabilities: {
      browserName: "chrome",
      cssSelectorsEnabled: true,
      javascriptEnabled: true,
      nativeEvents: false,
      rotatable: false,
      takesScreenshot: true,
      chrome_options: {
        args: %w(headless new-window no-sandbox disable-dev-shm-usage disable-gpu window-size=1200,1400)
      }
    }
  )
end

# NOTES -------------------------------------------------------------------------------------------------

# Go to https://mitmproxy.org/ and download the binarys. Extract them to /~ or
# wherever makes sense for the deployment.

# Run the following command to start a MITM server (assuming mitmdump was extracted to /~)
# ~/mitmdump -p 9000 --mode upstream:http://proxy.crawlera.com:8010 --set upstream_auth=dc5106a9eee74ef8896bbe4599e4c332: --ssl-insecure
# /home/deploy/mitm/mitmdump -p 9000 --mode upstream:http://proxy.crawlera.com:8010 --set upstream_auth=dc5106a9eee74ef8896bbe4599e4c332: --ssl-insecure
# If port 9000 is not available, modify the above command. You will also need
# to change the line below for proxy_server

# end NOTES ---------------------------------------------------------------------------------------------


Capybara.register_driver :headless_chrome do |app|
  Capybara::Selenium::Driver.load_selenium

  browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.args.merge(%w(--new-window --no-sandbox --disable-dev-shm-usage  --window-size=1200,1400))
    # opts.args << '--proxy-server=http://127.0.0.1:3128'
    opts.args << '--proxy-server=http://localhost:9000'
    opts.args << '--headless' unless ENV["HEADLESS"] == "0"
    opts.args << '--disable-gpu' if Gem.win_platform?
  end

  client = Selenium::WebDriver::Remote::Http::Default.new
  # client.open_timeout = 180

  # binding.pry

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: browser_options,
    http_client: client
  )
end

# Capybara.register_driver :headless_chrome do |app|
#   Capybara::Selenium::Driver.load_selenium
#
#   browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
#     opts.args.merge(%w(--new-window --no-sandbox --disable-dev-shm-usage  --window-size=1200,1400))
#     opts.args << '--headless' unless ENV["HEADLESS"] == "0"
#     opts.args << '--disable-gpu' if Gem.win_platform?
#   end
#
#   Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
# end

module CongressForms
  Error = Class.new(Exception) do
    attr_accessor :screenshot
  end

  autoload :Form, "congress_forms/form"
  autoload :WebForm, "congress_forms/web_form"
  autoload :CwcForm, "congress_forms/cwc_form"
  autoload :Actions, "congress_forms/actions"

  autoload :Repo, "congress_forms/repo"

  @@contact_congress_remote = "https://github.com/unitedstates/contact-congress.git"


  def self.contact_congress_remote=(location)
    @@contact_congress_remote = location
  end

  def self.contact_congress_remote
    @@contact_congress_remote
  end

  @@contact_congress_repository = nil

  def self.contact_congress_repository=(location)
    @@contact_congress_repository = location
  end

  def self.contact_congress_repository
    @@contact_congress_repository
  end

  @@auto_update_contact_congress = true

  def self.auto_update_contact_congress=(auto_update)
    @@auto_update_contact_congress = auto_update
  end

  def self.auto_update_contact_congress?
    @@auto_update_contact_congress
  end
end
