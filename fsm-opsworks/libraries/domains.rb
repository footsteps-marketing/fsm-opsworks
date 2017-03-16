module Domains
    include Chef::Mixin::ShellOut
    
    def get(app_root, app_domain)
        command = "php #{app_root}/get-mapped-domains.php"
        result = self.shell_out(command)
        
        Chef::Log.info("**************** DOMAINS RESULT: #{result.stdout}")
        Chef::Log.info("**************** DOMAINS ERROR:  #{result.stderr}")
        domains = result.stdout.split("\n")
        domains.unshift("#{app_domain}")

        return domains
    end
end