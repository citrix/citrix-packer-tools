# Packer Template For Windows 10 PRO 22H2

Packer template that will create image that includes installation of Citrix Virtual Delivery Agent, Chrome Browser, and Firefox Browser. Image also will run process of optimization using Citrix Optimizer.

## What will be installed

Script will install Citrix Virtual Delivery Agent as Master Image with MCSIO support. 
This is component needed for core functionality with Citrix Delivery Controller.

Script will run Citrix Optimizer with xml appropriate template you select.
Template is included inside Optmimizer zip file.

Optionally we will install Chrome browser. Default installation value is true.
Optionally we will install Firefox browser. Default installation value is true.

```shell
"install_browser_chrome_flag": "true"
"install_browser_firefox_flag": "true"
```

## Necessary files

Download HashiCorp Packer executable to run a process. You can put it in the same directory as your template.
Download Citrix Virtual Delivery Agent 2407 and upload it to storage account for download during installation process.
Download Citrix Optimizer and upload it to storage account for download during installation process.

## Setup variables
The template consists of three sections: variables, builders, and provisioners.
In variable section there are few variables that need to be set before running the automation

```shell
"client_id" : reference to enterprise application client id
"client_secret" : reference to enterprise applicatrion client secret
"client_object_id" : reference to enterprise application object id
"client_tenant_id" : reference to directory tenant id
"client_subscription_id" : reference to subscription id

"image_resource_group" : refrerence to existing azure resource group where image will be placed
"optimizer_template" : reference to xml template file that will be used in citrix optimizer

"vda_location" : url reference to blob in storage account where virtual delivery agent is stored
"optimizer_location" : url reference to blob in storage account where zip file of citrix optimizer is stored

"image_name" : prefix of name of the image and snapshot that will be used in caputring image. default value is "win_desktop_10_22h2" 
"location_setup" : directory location on virtual machine where scripts will be copied to for processing. default value is "c:\\setup",
```

## Running the automation

```shell
> .\packer.exe build .\win_desktop_10_22h2_packer_template.json
```
