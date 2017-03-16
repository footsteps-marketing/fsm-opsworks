class Chef::Recipe::Domains
    def self.get(app_root, app_domain)
        include Chef::Mixin::ShellOut
        
        command = "php #{app_root}/get-mapped-domains.php"
        domains = self.shell_out(command).stdout.split("\n")
        domains.unshift("#{app_domain}")

        return domains
    end
end