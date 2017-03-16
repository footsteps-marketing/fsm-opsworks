class Chef::Recipe::Domains
    include Chef::Mixin::ShellOut
    
    def self.get(app_root, app_domain)
        command = "php #{app_root}/get-mapped-domains.php"
        domains = self.shell_out(command).stdout.split("\n")
        domains.unshift("#{app_domain}")

        return domains
    end
end