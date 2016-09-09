# module Domains
#     include Chef::Recipe
# 
#     def self.get(app_root, app_domain)
#         domains = Array.new
#         ruby_block "check_curl_command_output" do
#             block do
#                 #tricky way to load this Chef::Mixin::ShellOut utilities
#                 Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
#                 command = "php #{app_root}/get-mapped-domains.php"
#                 command_out = shell_out(command)
#                 domains = command_out.stdout.split("\n")
#             end
#             action :create
#         end
# 
#         domains.unshift("#{app_domain}")
#
#         return domains
#     end
# end