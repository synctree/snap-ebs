snap-ebsc2-ebs-automatic-consistent-snapshot
===

Easier to use than it is to say, this project aims to provide easy, automatic,
and consistent snapshots for AWS EBS volumes on EC2 instances.

Some specific goals and how they are achieved:

 - *Safety*: refuses to operate unless everything seems ok, and tries desperately to leave your system no worse than it started
 - *Reliability*: comprehensive test sweet makes sure that SnapEbs behaves as expected, even in unexpected conditions.
 - *Visibility*: verbose logging options to inspect the decision-making process for any action
 - *Ease of Installation*: just install the gem and add one line to your crontab
 - *Ease of Use*: automatically detects volumes mounted to the machine
 - *Ease of Monitoring*: 100% visibility of operation can be gained from off-the-shelf monitoring solution plugins
 - *Maintainability*: well-organized code structure and a modern language 
 - *Extensibility*: plugin architecture makes it easy to add lock support for services
 - *Isolation*: plugin execution is isolated, so that an error in one is very unlikely to affect the others

Install
===

Dependencies - Amazon Linux
---

```
sudo yum install gcc \
                 glibc-devel \
                 make \
                 mysql-devel \
                 patch \
                 ruby-devel \
                 zlib-devel
```

```
gem install snap-ebsc2-ebs-automatic-consistent-snapshot
crontab -e
```

Testing
===

Because you'll be running this against production servers with critical data, it's important that the functionality is well-tested. A thorough, pessimistic, multi-layer test suite hopes to assuage your concerns about letting a computer handle such an important task. The test suite is unquestionably the most complex part of this project.

Unit Tests
---

Like any good Ruby software, this tool has a unit test suite that seeks mostly to verify the plumbing and ensure that there are no runtime errors on the expected execution paths. This is only the tip of the iceberg...

Vagrant Integration Testing
---

The integration layer contains an Ansible + Vagrant setup to configure clusters of services for live-fire testing (the AWS bits are mocked out via SnapEbs's `--mock` flag). Simply running `vagrant up` will build a cluster of servers running MySQL, MongoDB, etc, configured in a master/slave architecture as approprite for the given system.

There is also a set of Ansible tasks that verify the operation of each plugin under **both ideal and pathological** conditions. This means that SnapEbs runs reliably, even when the services it operates on do not. Things like timeouts and service restart failures are modeled via `socat`, and assertions are made on the correct error output for each condition. For more info on how this is done, check `roles/integration-test/tasks/*.yml`

