current_dir = File.absolute_path(File.dirname(__FILE__))

log_level                 :info
log_location              STDOUT

file_cache_path           "#{current_dir}"
data_bag_path             "#{current_dir}/data_bags"
encrypted_data_bag_secret "#{current_dir}/data_bag_key"
cookbook_path             [ "#{current_dir}/cookbooks" ]
role_path                 "#{current_dir}/roles"
