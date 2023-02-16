# Packer_Windows

## Introduction

This is a Packer template that build Windows EC2 instances in AWS.

It has been tested with Windows 2016/2019 and 2022.

The base build includes Chocolatey.

This Packer template builds within a VPC and it doesn't depend on IAM Policies as it got the required permissions to get the image done.

## Requirements:

* This has been implemented using `Packer v1.8.5`
* Enough permissions in AWS to create EC2 resources in AWS.


## Instructions

The template can be run as per the example below:

```
packer init win_2022.pkr.hcl 
packer build -var 'windows_server_version=2022' win_2022.pkr.hcl
```

## Variables

The folllowing variables can be defined:

| Variables | Type | Description |
| --- | --- | --- |
| aws_region | String | AWS Region |
| vpc_id | String | VPC ID |
| subnet_id | String | VPC Subnet ID |
| cidr_whitelisting | List(string) | CIDRs to whitelist During the Build |
| windows_server_version | String | Windows Server Version |
| instance_type | String | EC2 Instance Type |
| volume_size | String | AMI Volume Size |
| tags | Map(String) | Map of Tags |

## References

 * Packer - https://www.packer.io/
 * Chocolatey - https://chocolatey.org/