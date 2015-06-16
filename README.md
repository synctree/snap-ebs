easy-ec2-ebs-automatic-consistent-snapshot
===

Easier to use than it is to say, this project aims to provide easy, automatic,
and consistent snapshots for AWS EBS volumes on EC2 instances.

Some specific goals and how they are achieved:

 - *Safety*: refuses to operate unless everything seems ok, and tries desperately to leave your system no worse than it started
 - *Visibility*: verbose logging options to inspect the decision-making process for any action
 - *Ease of Installation*: just install the gem and add one line to your crontab
 - *Ease of Use*: automatically detects volumes mounted to the machine
 - *Ease of Monitoring*: 100% visibility of operation can be gained from off-the-shelf monitoring solution plugins
 - *Maintainability*: well-organized code structure and a modern language 
 - *Extensibility*: plugin architecture makes it easy to add lock support for services
 - *Reliability*: comprehensive test sweet makes sure that the build is never (too badly) broken
 - *Isolation*: plugin execution is isolated, so that an error in one is very unlikely to affect the others
 - *Flexibility*: 

Install
===
```
gem install easy-ec2-ebs-automatic-consistent-snapshot
crontab -e
```

