actions :deploy

attribute :name, :kind_of => String, :name_attribute => true, :required => true
attribute :app_options, :kind_of => Hash, :default => nil
attribute :upgrade_code => String, :default => nil