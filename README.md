# Packer Image Management Module for Citrix® Virtual Apps and Desktops
The Packer Image Management Module for Citrix® Virtual Apps and Desktops aims to streamline the process of image management by creating custom golden image with Citrix Virtual Delivery Agent (VDA). This module helps install optional applications like Google Chrome and Mozilla Firefox and runs the Citrix Optimizer to improve image efficiency by removing unnecessary bloatware, resulting in optimized performance and resource utilization. A single command can be used to start the process of creating the image using packer software. **Please note that this module is still in Tech Preview.**

# Environment Requirement
Hashicorp Packer (https://github.com/hashicorp/packer)

# Guides
[Deployment Guide: Using HashiCorp Packer to Automate the Creation of Master Images](https://community.citrix.com/tech-zone/build/deployment-guides/master-images-with-packer/)
[Installing and Configuring Ansible, Terraform, and Packer for Citrix Infrastructure-as-Code-based Environments](https://community.citrix.com/tech-zone/build/deployment-guides/create-iac-vm/)

# Related Citrix Automation Repositories
|            Title            |            Details            |
|-----------------------------|-------------------------------|
| [Plugin for Terraform Provider for Citrix®](https://github.com/citrix/terraform-provider-citrix) | Terraform provider plugin to manage Citrix products including CVAD, DaaS, StoreFront, and WEM via Terraform IaC. |
| [Citrix Ansible Tools](https://github.com/citrix/citrix-ansible-tools) | Playbooks to install Citrix components using automation such as the VDA. |
| [Site Deployment Module for Citrix® Virtual Apps and Desktops](https://github.com/citrix/citrix-cvad-site-deployment-module) | Uses PowerShell to drive Terraform files to create a fully functional CVAD site. |

# License 
This project is Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

<sub>Copyright © 2025. Citrix Systems, Inc. All Rights Reserved.</sub>
