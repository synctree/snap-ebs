snap-ebs
===

![snap-ebs logo -- the snapping turtle](http://i.imgur.com/DgUZmIq.png)
> Backup your EBS volumes in a snap

This project aims to provide easy, automatic, and consistent snapshots for AWS
EBS volumes on EC2 instances.

Some specific goals and how they are achieved:

 - *Safety*: refuses to operate unless everything seems ok, and tries desperately to leave your system no worse than it was found
 - *Reliability*: comprehensive test suite ensures that `snap-ebs` behaves as expected, even in unexpected conditions
 - *Visibility*: verbose logging options to inspect the decision-making process for any action or non-action
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

gem install snap-ebs
```

Usage
===

1. Create an IAM user with the necessary permissions: `ec2:CreateSnapshot`, `ec2:DescribeTags`, `ec2:DescribeVolumes`
2. Download the user's credentials file (as `.csv`) and put it somewhere on the server (I would suggest `/opt/snap-ebs-credentials.csv`, ideally with mode 600 and owned by the user who will run `snap-ebs`)
3. Add something like this to your root crontab:
```
0 0 * * * * /bin/bash -lc 'snap-ebs -c /opt/snap-ebs-credentials.csv --directory /data,/log,/journal --logfile /var/log/snap-ebs.log --mongo --mongo-shutdown yes'
```

4. If you're using rvm with a passwordless-sudo user, you might use this instead:
```
0 0 * * * * /bin/bash -lc 'rvmsudo snap-ebs -c /opt/snap-ebs-credentials.csv --directory /data,/log,/journal --logfile /var/log/snap-ebs.log --mongo --mongo-shutdown yes'
```

Testing
===

Because you'll be running this against production servers with critical data, it's important that the functionality is well-tested. A thorough, pessimistic, multi-layer test suite hopes to assuage your concerns about letting a computer handle such an important task. The test suite is unquestionably the most complex part of this project.

Unit Tests
---

```
rspec spec/*
```

Like any good Ruby software, this tool has a unit test suite that seeks mostly to verify the plumbing and ensure that there are no runtime errors on the expected execution paths. This is only the tip of the iceberg...

Vagrant Integration Testing
---

```
vagrant up
```

The integration layer contains an Ansible + Vagrant setup to configure clusters of services for live-fire testing (the AWS bits are mocked out via `snap-ebs`'s `--mock` flag). Simply running `vagrant up` will build a cluster of servers running MySQL, MongoDB, etc, configured in a master/slave architecture as approprite for the given system.

There is also a set of Ansible tasks that verify the operation of each plugin under **both ideal and degenerate** conditions. This means that `snap-ebs` runs reliably, even when the services it operates on do not. Things like timeouts and service restart failures are modeled via `socat`, and assertions are made on the correct error output for each condition. For more info on how this is done, check `roles/integration-test/tasks/*.yml`

Your local copy of `snap-ebs` is mounted to each machine, so all modifications carry over immediately. If you are hacking on `snap-ebs` and just want to run the integration tests, rather than the full ansible provisioning playbook, simply add `-t test` to the command Vagrant spits out when starting the ansible provisioner.
