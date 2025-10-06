# TikTok Open SDK

[![Gem Version](https://img.shields.io/badge/gem-v0.4.0-blue.svg)](https://rubygems.org/gems/tiktok-open-sdk)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.0.0-red.svg)](https://www.ruby-lang.org/en/downloads/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE.txt)
[![CI](https://github.com/pochkuntaras/tiktok-open-sdk/actions/workflows/main.yml/badge.svg)](https://github.com/pochkuntaras/tiktok-open-sdk/actions/workflows/main.yml)

A comprehensive Ruby SDK for integrating with TikTok Open API. This gem provides OAuth 2.0 authentication, user authorization, and HTTP client functionality for accessing TikTok APIs seamlessly.

## Features

- **OAuth 2.0 Authentication** – Seamless OAuth flow for secure integration
- **OmniAuth Strategy** – Ready-to-use OmniAuth strategy for Rails applications
- **Client Authentication** – Server-to-server authentication with client credentials
- **Token Management** – Easy access token exchange and refresh
- **User API** – Convenient methods to access user information
- **Post API** – Methods for querying creator information and video publishing
- **HTTP Client** – Built-in client for interacting with TikTok APIs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tiktok-open-sdk'
```

And then execute:

```bash
bundle install
```

Or install it directly:

```bash
gem install tiktok-open-sdk
```

## Configuration

Before using the SDK, you need to configure it with your TikTok app credentials:

```ruby
require 'tiktok/open/sdk'

Tiktok::Open::Sdk.configure do |config|
  # Required: Your TikTok app credentials
  config.client_key    = 'your_client_key'
  config.client_secret = 'your_client_secret'
  
  # Optional: Customize OAuth settings
  config.user_auth.scopes       = %w[user.info.basic video.list]
  config.user_auth.redirect_uri = 'https://your-app.com/auth/callback'
  
  # Optional: Custom URLs (defaults are provided)
  config.user_auth.auth_url         = 'https://www.tiktok.com/v2/auth/authorize/'
  config.user_auth.token_url        = 'https://open.tiktokapis.com/v2/oauth/token/'
  config.user_auth.revoke_token_url = 'https://open.tiktokapis.com/v2/oauth/revoke/'
  config.user_info_url              = 'https://open.tiktokapis.com/v2/user/info/'
  config.creator_info_query_url     = 'https://open.tiktokapis.com/v2/post/publish/creator_info/query/'

  # Optional: Enable OmniAuth strategy auto-loading
  config.load_omniauth = true
end
```

### Getting TikTok App Credentials

1. Visit [TikTok for Developers](https://developers.tiktok.com/)
2. Create a new app or use an existing one
3. Navigate to your app's settings
4. Copy your **Client Key** and **Client Secret**

## Usage

### Basic OAuth Flow

#### 1. Generate Authorization URI

```ruby
# Generate the authorization URI for user login
auth_uri = Tiktok::Open::Sdk.user_auth.authorization_uri

# Or with custom parameters
auth_uri = Tiktok::Open::Sdk.user_auth.authorization_uri(
  scope:        'user.info.basic,video.list',
  redirect_uri: 'https://your-app.com/callback',
  state:        'random_state_string'
)

puts auth_uri.to_s
# => "https://www.tiktok.com/v2/auth/authorize/?client_key=your_key&response_type=code&scope=user.info.basic&redirect_uri=https://your-app.com/callback"
```

#### 2. Handle Authorization Callback

After the user authorizes your app, TikTok will redirect to your `redirect_uri` with an authorization code:

```ruby
# Extract the code from the callback URL
code = params[:code] # From your web framework (Rails, Sinatra, etc.)

# Exchange the code for an access token
response = Tiktok::Open::Sdk.user_auth.fetch_access_token(code: code)

if response[:success]
  access_token  = response[:response][:access_token]
  refresh_token = response[:response][:refresh_token]
  expires_in    = response[:response][:expires_in]
  
  puts "Access Token: #{access_token}"
  puts "Refresh Token: #{refresh_token}"
  puts "Expires in: #{expires_in} seconds"
else
  puts "Error: #{response[:response]}"
end
```

#### 3. Refresh Access Token

```ruby
# Refresh an expired access token
response = Tiktok::Open::Sdk.user_auth.refresh_access_token(
  refresh_token: 'your_refresh_token'
)

if response[:success]
  new_access_token = response[:response][:access_token]

  puts "New Access Token: #{new_access_token}"
end
```

#### 4. Revoke Access Token

```ruby
# Revoke a refresh token
response = Tiktok::Open::Sdk.user_auth.revoke_access_token(
  token: 'your_refresh_token'
)

puts "Token revoked successfully" if response[:success]
```

### Client Authentication

For server-to-server authentication, you can obtain a client access token:

```ruby
# Fetch client access token
response = Tiktok::Open::Sdk.client_auth.fetch_client_token

if response[:success]
  client_token = response[:response][:access_token]
  expires_in   = response[:response][:expires_in]
  
  puts "Client Token: #{client_token}"
  puts "Expires in: #{expires_in} seconds"
else
  puts "Error: #{response[:response]}"
end
```

**Note:** Client tokens are used for server-to-server authentication and have different scopes and permissions than user tokens.

### Using the Post API

The SDK provides convenient methods for interacting with TikTok's Post API:

#### Creator Info Query

Query creator information for video publishing:

```ruby
# Get creator information
response = Tiktok::Open::Sdk.post.creator_info_query(access_token: access_token)

if response[:success]
  creator_data = response[:response][:data]

  puts "Creator Avatar: #{creator_data[:creator_avatar_url]}"
  puts "Creator Nickname: #{creator_data[:creator_nickname]}"
  puts "Max Video Duration: #{creator_data[:max_video_post_duration_sec]} seconds"
  puts "Privacy Options: #{creator_data[:privacy_level_options]}"
else
  puts "Error: #{response[:response][:error][:message]}"
end
```

### Using the User API

The SDK provides a convenient way to access user information:

```ruby
# Get user information
response = Tiktok::Open::Sdk.user.get_user_info(
  access_token: access_token,
  fields: %w[open_id union_id avatar_url display_name]
)

if response[:success]
  user_data = response[:response][:data][:user]
  
  puts "User ID: #{user_data[:open_id]}"
  puts "Display Name: #{user_data[:display_name]}"
else
  puts "Error: #{response[:response][:error][:message]}"
end
```

Available user fields include:
- `open_id` - User's Open ID
- `union_id` - User's Union ID
- `avatar_url` - User's avatar URL
- `display_name` - User's display name
- `username` - User's username
- And more (see documentation for full list)

### Using OmniAuth Strategy

The SDK provides a ready-to-use OmniAuth strategy for Rails applications:

#### Rails Setup

Add the OmniAuth strategy to your Rails application:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.omniauth(
    :tiktok_open_sdk,
    Rails.application.credentials.dig(:tiktok, :client_key),
    Rails.application.credentials.dig(:tiktok, :client_secret),
    scope:         'user.info.basic,user.info.profile,user.info.stats',
  )
end
```

Or use the SDK configuration:

```ruby
# config/initializers/tiktok_sdk.rb
Tiktok::Open::Sdk.configure do |config|
  config.client_key             = Rails.application.credentials.dig(:tiktok, :client_key)
  config.client_secret          = Rails.application.credentials.dig(:tiktok, :client_secret)
  config.user_auth.scopes       = %w[user.info.basic video.publish]
  config.user_auth.redirect_uri = "#{Rails.application.config.action_mailer.asset_host.chomp('/')}/users/auth/tiktok_open_sdk/callback"
  config.load_omniauth          = true
end
```

#### OmniAuth Callback

Handle the OmniAuth callback in your controller:

```ruby
# app/controllers/omniauth_callbacks_controller.rb
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def tiktok_open_sdk
    @auth = request.env['omniauth.auth']

    # Find or create user based on TikTok auth data
    @user = User.find_for_oauth(@auth)

    # ...

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message :notice, :success, kind: 'TikTok'
    else
      session['devise.provider_data'] = @auth.except('extra')
      redirect_to new_user_registration_url
    end
  end
end
```

#### Supported Scopes

The OmniAuth strategy supports the following TikTok scopes:

- `user.info.basic` - Basic user info: open_id, union_id, display_name, avatar URLs
- `user.info.profile` - Profile info: username, bio_description, profile_deep_link, is_verified
- `user.info.stats` - Statistics: follower_count, following_count, likes_count, video_count

### Using the HTTP Client

The SDK includes a flexible HTTP client for making API calls:

```ruby
# GET request using request method
response = Tiktok::Open::Sdk::HttpClient.request(
  :get,
  'https://open.tiktokapis.com/v2/user/info/',
  params: {
    fields: 'open_id,union_id,avatar_url'
  },
  headers: {
    'Authorization' => "Bearer #{access_token}"
  }
)

# GET request using get method
response = Tiktok::Open::Sdk::HttpClient.get(
  'https://open.tiktokapis.com/v2/user/info/',
  params: {
    fields: 'open_id,union_id,avatar_url'
  },
  headers: {
    'Authorization' => "Bearer #{access_token}"
  }
)

# POST request
response = Tiktok::Open::Sdk::HttpClient.post(
  'https://open.tiktokapis.com/v2/video/list/',
  headers: {
    'Authorization' => "Bearer #{access_token}",
    'Content-Type'  => 'application/json'
  },
  body: {
    # ...
  }
)

# Check response
if response.is_a?(Net::HTTPSuccess)
  data = JSON.parse(response.body)

  puts "Success: #{data}"
else
  puts "Error: #{response.code} - #{response.body}"
end
```

### Complete Rails Example

Here's a complete example for a Rails application:

```ruby
# config/initializers/tiktok_sdk.rb
require 'tiktok/open/sdk'

Tiktok::Open::Sdk.configure do |config|
  config.client_key             = Rails.application.credentials.tiktok_client_key
  config.client_secret          = Rails.application.credentials.tiktok_client_secret
  config.user_auth.scopes       = %w[user.info.basic video.list]
  config.user_auth.redirect_uri = "#{Rails.application.routes.url_helpers.root_url}auth/tiktok/callback"
end
```

```ruby
# app/controllers/tiktok_auth_controller.rb
class TiktokAuthController < ApplicationController
  def login
    # Generate authorization URI
    auth_uri = Tiktok::Open::Sdk.user_auth.authorization_uri(
      state: session[:state] = SecureRandom.hex(16)
    )
    
    redirect_to auth_uri.to_s
  end
  
  def callback
    # Verify state parameter for CSRF protection
    if params[:state] != session[:state]
      redirect_to root_path, alert: 'Invalid state parameter'

      return
    end
    
    # Exchange code for access token
    response = Tiktok::Open::Sdk.user_auth.fetch_access_token(code: params[:code])
    
    if response[:success]
      token_data = response[:response]
      
      # Store tokens securely (consider using encrypted attributes)
      session[:tiktok_access_token]  = token_data[:access_token]
      session[:tiktok_refresh_token] = token_data[:refresh_token]
      
      # Fetch user information
      user_response = Tiktok::Open::Sdk::OpenApi::User.get_user_info(
        access_token: token_data[:access_token],
        fields: %w[open_id display_name avatar_url]
      )
      
      if user_response[:success]
        user_data = user_response[:response][:data][:user]
        session[:tiktok_user_name] = user_data[:display_name]
        session[:tiktok_avatar] = user_data[:avatar_url]
      end
      
      redirect_to dashboard_path, notice: 'Successfully connected to TikTok!'
    else
      redirect_to root_path, alert: 'Failed to authenticate with TikTok'
    end
  end
  
  def disconnect
    if session[:tiktok_refresh_token]
      Tiktok::Open::Sdk.user_auth.revoke_access_token(
        token: session[:tiktok_refresh_token]
      )
    end
    
    session.delete(:tiktok_access_token)
    session.delete(:tiktok_refresh_token)
    
    redirect_to root_path, notice: 'Disconnected from TikTok'
  end
end
```

## API Reference

### Configuration

#### `Tiktok::Open::Sdk.configure`

Configures the SDK with your app credentials and settings.

```ruby
Tiktok::Open::Sdk.configure do |config|
  config.client_key             = 'your_client_key'    # Required
  config.client_secret          = 'your_client_secret' # Required
  config.user_auth.scopes       = %w[user.info.basic]  # Optional
  config.user_auth.redirect_uri = 'https://...'        # Optional
  config.user_info_url          = 'https://open.tiktokapis.com/v2/user/info/' # Optional
end
```

### User Authentication

#### `authorization_uri(params = {})`

Generates the OAuth authorization URI.

**Parameters:**
- `scope` (String, optional) - Comma-separated scopes
- `redirect_uri` (String, optional) - Custom redirect URI
- `state` (String, optional) - State parameter for CSRF protection

**Returns:** `URI` object

#### `fetch_access_token(code:, redirect_uri: nil)`

Exchanges authorization code for access token.

**Parameters:**
- `code` (String, required) - Authorization code from callback
- `redirect_uri` (String, optional) - Redirect URI used in authorization

**Returns:** Hash with `:success`, `:code`, and `:response` keys

#### `refresh_access_token(refresh_token:)`

Refreshes an expired access token.

**Parameters:**
- `refresh_token` (String, required) - Refresh token

**Returns:** Hash with `:success`, `:code`, and `:response` keys

#### `revoke_access_token(token:)`

Revokes a refresh token.

**Parameters:**
- `token` (String, required) - Refresh token to revoke

**Returns:** Hash with `:success`, `:code`, and `:response` keys

### Client Authentication

#### `fetch_client_token`

Obtains a client access token for server-to-server authentication.

**Returns:** Hash with `:success`, `:code`, and `:response` keys

**Example Response:**
```ruby
{
  success:  true,
  code:     200,
  response: {
    access_token: "client_token_here",
    expires_in:   7200,
    token_type:   "Bearer"
  }
}
```

### User API

#### `get_user_info(access_token:, fields:, validate: true)`

Retrieves user information from the TikTok Open API.

**Parameters:**
- `access_token` (String, required) - OAuth2 access token for authentication
- `fields` (Array<String>, required) - User fields to retrieve (must be valid fields)
- `validate` (Boolean, optional) - Whether to validate the token and fields (default: true)

**Returns:** Hash with `:success`, `:code`, and `:response` keys

**Available Fields:**
- `open_id` - Unique identifier for the user within the current application
- `union_id` - Persistent identifier for the user across different applications from the same developer
- `avatar_url` - URL to the user's profile image
- `avatar_url_100` - URL to the user's profile image in 100x100 pixel size
- `avatar_large_url` - URL to the user's profile image in higher resolution
- `display_name` - User's display name shown on their TikTok profile
- `bio_description` - User's biography text (if available)
- `profile_deep_link` - Direct link to the user's TikTok profile page
- `is_verified` - Boolean indicating if the account is verified by TikTok
- `username` - User's unique TikTok username
- `follower_count` - Number of followers the user has
- `following_count` - Number of accounts the user is following
- `likes_count` - Total number of likes received across all user's videos
- `video_count` - Total number of publicly posted videos by the user

### Post API

#### `creator_info_query(access_token:)`

Queries creator information from the TikTok Open API for video publishing.

**Parameters:**
- `access_token` (String, required) - OAuth2 access token for authentication

**Returns:** Hash with `:success`, `:code`, and `:response` keys

**Response Data:**
- `creator_avatar_url` - Creator's avatar URL
- `creator_nickname` - Creator's display name
- `creator_username` - Creator's username
- `stitch_disabled` - Whether stitch is disabled for the creator
- `comment_disabled` - Whether comments are disabled for the creator
- `duet_disabled` - Whether duet is disabled for the creator
- `max_video_post_duration_sec` - Maximum video duration in seconds
- `privacy_level_options` - Available privacy level options

### HTTP Client

#### `request(method, url, params: {}, headers: {}, body: nil)`

Performs HTTP requests.

**Parameters:**
- `method` (Symbol) - HTTP method (`:get`, `:post`)
- `url` (String) - Request URL
- `params` (Hash, optional) - Query parameters
- `headers` (Hash, optional) - HTTP headers
- `body` (Hash, optional) - Request body

**Returns:** `Net::HTTPResponse` object

#### `get(url, params: {}, headers: {})`

Convenience method for GET requests.

**Parameters:**
- `url` (String) - Request URL
- `params` (Hash, optional) - Query parameters
- `headers` (Hash, optional) - HTTP headers

**Returns:** `Net::HTTPResponse` object

#### `post(url, params: {}, headers: {}, body: nil)`

Convenience method for POST requests.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run tests with coverage
bundle exec rspec --format documentation
```

### Code Quality

This project uses RuboCop for code quality:

```bash
# Check code style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pochkuntaras/tiktok-open-sdk. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

### Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/tiktok-open-sdk.git`
3. Install dependencies: `bundle install`
4. Create a feature branch: `git checkout -b feature-name`
5. Make your changes and add tests
6. Run tests: `bundle exec rspec`
7. Check code style: `bundle exec rubocop`
8. Commit your changes: `git commit -am 'Add some feature'`
9. Push to the branch: `git push origin feature-name`
10. Submit a pull request

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Links

- [TikTok for Developers](https://developers.tiktok.com/)
- [TikTok Open API Documentation](https://developers.tiktok.com/doc/)
- [RubyGems Page](https://rubygems.org/gems/tiktok-open-sdk)
- [GitHub Repository](https://github.com/pochkuntaras/tiktok-open-sdk)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.
