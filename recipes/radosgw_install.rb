#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'ceph-chef'

node['ceph']['radosgw']['packages'].each do |pck|
  if pck.include?('=')
    pck_name, pck_version = pck.split('=')
    package pck_name do
      version pck_version
    end
  else
    package pck
  end
end

platform_family = node['platform_family']

case platform_family
when 'rhel'
  if node['ceph']['version'] == 'hammer'
    # Known issue - https://access.redhat.com/solutions/1546303
    # 2015-10-05
    cookbook_file '/etc/init.d/ceph-radosgw' do
      source 'ceph-radosgw'
      owner 'root'
      group 'root'
      mode '0755'
    end
  else
    template '/usr/lib/systemd/system/ceph-radosgw@.service' do
      notifies :run, 'execute[ceph-systemctl-daemon-reload]', :immediately
      mode '0644'
    end
  end
end

cookbook_file '/usr/local/bin/radosgw-admin2' do
  source 'radosgw-admin2'
  owner 'root'
  group 'root'
  mode 0755
end

cookbook_file '/usr/local/bin/rgw_s3_api.py' do
  source 'rgw_s3_api.py'
  owner 'root'
  group 'root'
  mode 0755
end

include_recipe 'ceph-chef::install'
