include_recipe "ethtool::default"

cookbook_file "/etc/network/if-up.d/ethtool" do
  source "ifup-ethtool"
  mode 0755
  owner "root"
  group "root"
end

directory "/etc/ethtool.d" do
  mode 0755
  owner "root"
  group "root"
end

if node[:ethtool]
  if node[:ethtool][:interfaces]

    node[:ethtool][:interfaces].each do |iface, config|
      template "/etc/ethtool.d/#{iface}.conf" do
        source "iface.conf.erb"
        mode 0644
        owner "root"
        group "root"
        variables :config => config
      end
    end

  end
end