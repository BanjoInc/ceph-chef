#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: mds
#
# Copyright 2011, DreamHost Web Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'ceph-chef'
include_recipe 'ceph-chef::mds_install'

# cluster = 'ceph'
cluster = node['ceph']['cluster']

directory "/var/lib/ceph/mds/#{cluster}-#{node['hostname']}" do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode node['ceph']['mode']
  recursive true
  action :create
end

keyring = "/var/lib/ceph/mds/#{cluster}-#{node['hostname']}/keyring"
# If no initial key exists then this will run
execute 'generate-client-mds' do
  command <<-EOH
      sudo ceph auth get-or-create mds.#{node['hostname']} osd 'allow *' mon 'allow rwx' -o #{keyring} --cluster #{node['ceph']['cluster']}
  EOH
  creates keyring
  not_if "test -s #{keyring}"
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

file "/var/lib/ceph/mds/#{cluster}-#{node['hostname']}/done" do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode 00644
end

service_type = node['ceph']['osd']['init_style']

filename = case service_type
           when 'upstart'
             'upstart'
           else
             'sysvinit'
           end
file "/var/lib/ceph/mds/#{cluster}-#{node['hostname']}/#{filename}" do
  owner node['ceph']['owner']
  group node['ceph']['group']
  mode 00644
end

template '/etc/systemd/system/ceph-mds@.service' do
  notifies :run, 'execute[ceph-systemctl-daemon-reload]', :immediately
  action :create
  only_if { rhel? && systemd? }
end

service 'ceph_mds' do
  case service_type
  when 'upstart'
    service_name 'ceph-mds-all-starter'
    provider Chef::Provider::Service::Upstart
  else
    service_name "ceph-mds@#{node['hostname']}"
  end
  action [:enable, :start]
  supports :restart => true
end
