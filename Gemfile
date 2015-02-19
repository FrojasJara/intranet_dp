if RUBY_VERSION =~ /1.9/
	Encoding.default_external = Encoding::UTF_8
	Encoding.default_internal = Encoding::UTF_8
end
source 'http://rubygems.org'
source 'http://gems.github.com'
RAILS_VERSION = '~> 3.1.11'
DM_VERSION    = '~> 1.2.0'

gem 'debugger'
gem 'activesupport',      RAILS_VERSION, :require => 'active_support'
gem 'actionpack',         RAILS_VERSION, :require => 'action_pack'
gem 'actionmailer',       RAILS_VERSION, :require => 'action_mailer'
gem 'activeresource',     RAILS_VERSION, :require => 'active_resource'
gem 'railties',           RAILS_VERSION, :require => 'rails'
gem 'tzinfo'

gem 'dm-rails',               DM_VERSION

gem 'haml'
gem 'simple_form', '2.1.0'
gem 'slim'

gem 'dm-mysql-adapter',     DM_VERSION
#gem 'dm-postgres-adapter',  DM_VERSION

gem 'dm-migrations', 		:git => 'https://github.com/avillagran/dm-migrations.git'
gem 'dm-types',             DM_VERSION
gem 'dm-validations',       DM_VERSION
gem 'dm-constraints',       DM_VERSION
gem 'dm-transactions',      DM_VERSION
gem 'dm-aggregates',        DM_VERSION
gem 'dm-timestamps',        DM_VERSION
gem 'dm-observer',          DM_VERSION
gem 'dm-serializer',       	DM_VERSION
gem 'dm-ar-finders'
gem 'dm-is-state_machine'
gem 'dm-polymorphic', :git => 'https://github.com/gorner/dm-polymorphic.git'
gem 'dm-crud', '0.0.4', git: 'https://github.com/avillagran/dm-crud.git'
gem 'dm-historylog', '0.0.2', git: 'http://github.com/avillagran/dm-historylog.git'



gem 'jquery-rails'


# Deploy with Capistrano
 gem 'capistrano'
 
 gem 'kaminari'


gem 'chunky_png'
gem 'barby'
gem 'mini_magick', :git => 'https://github.com/probablycorey/mini_magick.git'
gem 'prawn', :git => 'https://github.com/prawnpdf/prawn.git' # PDF!

gem 'dm-zone-types'

group :development do
	gem 'quiet_assets'
	gem 'rails-dev-tweaks', '~> 0.6.1'
	gem 'webrick', '1.3.1' #[AV] Quita WARNs de la consola!! :D
    gem 'pry' # Depurador, usar binding.pry
end

group :production do
	gem 'uglifier'
end

gem 'dm-utils', :git => "https://github.com/mrsangrin/dm-utils.git"



group :test do
 # Pretty printed test output
  gem 'turn', '~> 0.8.3', :require => false
end

gem 'colored'
gem 'will_paginate', '~> 3.0.2' # paginación [AV]
gem 'bootstrap-will_paginate', git: 'https://github.com/yrgoldteeth/bootstrap-will_paginate.git'

# => Exportaciones
gem 'to_xls'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

gem 'will_paginate', '~> 3.0.2' # paginación [AV]
gem 'bootstrap-will_paginate', git: 'https://github.com/yrgoldteeth/bootstrap-will_paginate.git'

gem 'exception_notification'
# gem 'puma', git: 'https://github.com/puma/puma.git'
gem 'puma'
#gem 'thin'
gem 'rvm-capistrano'

gem 'debugger'

gem "tinder"
gem "pry"

#gem 'assets'
gem 'therubyracer'
gem 'less'
#gem 'less-assets'
#alertas jquery mensajes
gem 'alertify-rails'
