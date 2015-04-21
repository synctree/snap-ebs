easy-ec2-ebs-automatic-consistent-snapshot
===

Easier to use than it is to say, this project aims to provide easy, automatic,
and consistent snapshots for AWS EBS volumes on EC2 instances.

Some specific goals and how they are achieved:

 - *Ease of Installation*: just install the gem and add one line to your crontab
 - *Ease of Use*: automatically detects volumes mounted to the machine
 - *Maintainability*: well-organized code structure and a modern language 
 - *Extensibility*: plugin architecture makes it easy to add lock support for services
 - *Reliability*: comprehensive test sweet makes sure that the build is never (too badly) broken

Install
===
```
gem install easy-ec2-ebs-automatic-consistent-snapshot
crontab -e
```
