# Original source: https://github.com/scalarium/cookbooks/tree/master/ebs
# Updated by Jonathan Rudenberg (jonathan@titanous.com)

name "ebs"
maintainer "John Alberts"
maintainer_email "john@alberts.me"
description "Mounts attached EBS volumes"
version "0.3.13"
license "Apache 2.0"
recipe "ebs::volumes", "Mounts attached EBS volumes"
recipe "ebs::raids", "Mounts attached EBS RAIDs"
recipe "ebs::persistent", "Mounts volumes defined in attributes"

depends 'aws', '>= 2.7.0'
depends 'delayed_evaluator'
