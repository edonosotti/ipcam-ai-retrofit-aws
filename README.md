# IPCam AI Retrofit - AWS version

## Description

This application uses AWS managed services to process images from IP cameras with AI and trigger actions.

## DISCLAIMER - IMPORTANT INFORMATION

THIS IS AN EXPERIMENTAL PROJECT AND MUST **NOT** BE CONSIDERED AS A RELIABLE, TRUSTWORTHY SOFTWARE
TO DEPEND ON. IT COMES WITH NO WARRANTY OF ANY KIND, USE IT AT YOUR OWN RISK. DO NOT USE IT IN
ANY "PRODUCTION", "LIVE" or "MISSION-CRITICAL" ENVIRONMENT AND DO NOT EXPECT IT TO EITHER PROTECT
YOUR SAFETY, THE SAFETY OF OTHERS OR THE SAFETY OF YOUR PROPERTIES.
PLEASE ALSO [READ THE LICENSE](LICENSE) CAREFULLY BEFORE INSTALLING AND RUNNING THE CODE.

## Code branches

 * `dev` - development branch, latest and greatest version of the code that shoud *not* be expected to work
 * `master` - distribution branch, this code is expected to work (NO WARRANTIES GIVEN, PLEASE READ THE DISCLAMER PARAGRAPH!)

## Prerequisites

 * 1+ IP cameras able to send e-mails with attached pictures (triggered by any event of your choice)
 * An Internet Domain Name to set up a recipient e-mail address with
 * An [`Amazon Web Services (AWS)`](https://aws.amazon.com) account
 * [`Python 3.7.x`](https://www.python.org)
 * [`Terraform`](https://www.terraform.io/downloads.html)
 * (optional) A [`SendGrid`](https://sendgrid.com) account

## Quick Start

Assuming that all the **Prerequisites** are met and `AWS` tools have been
[installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
on your machine, deploying this application is as easy as running:

```
$ cd terraform
$ terraform init
$ terraform apply
```

You will be prompted to input a few settings. If you opted to use `SendGrid` to
receive and send e-mails, you will also need to manually set up your `SendGrid` account
and `Inbound Parse Webhook`, pointing it to the `AWS` `Lambda` `API Gateway` URL
provisioned during the installation. For more information, please see:

 - https://sendgrid.com/docs/API_Reference/Parse_Webhook/inbound_email.html
 - https://sendgrid.com/docs/for-developers/parsing-email/setting-up-the-inbound-parse-webhook/

## Detailed installation instructions

### Preparing for deployment

#### `AWS` authentication

`Terraform` supports several means of providing credentials for authentication.

The most safe and convenient ways of providing said credentials are:
 * [Environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
 * [Shared credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
**DO NOT** statically store credentials in `Terraform` plans. They could be
accidentally committed to a repository.

`Terraform` will automatically try to read default credentials from the *environment variables*
or the *shared credentials file*. Such information can be manually overridden from the command line:

```
$ AWS_PROFILE=my_profile AWS_DEFAULT_REGION=eu-west-1 terraform plan
```

Please see the AWS documentation linked above and the
[`Terraform AWS provider` documentation](https://www.terraform.io/docs/providers/aws/index.html)
for more information.

#### Remote `S3` `backend` for `Terraform` state

By default the included `Terraform` `plan` will store its
[`state`](https://www.terraform.io/docs/state/index.html) locally.
In order to safely store your state remotely, have an automated backup
and manage your installation from multiple computers, you can enable the
`S3 backend` uncommenting (and updating, if needed) its configuration
in the [`main.tf`](main.tf) file. For more information, please read the
[`S3 backend` documentation](https://www.terraform.io/docs/backends/types/s3.html).

#### Inbound e-mail accounts

Inbound e-mails can either be received through [`Amazon Amazon Simple Email Service (SES)`](https://aws.amazon.com/ses/)
or [`SendGrid`](https://sendgrid.com).

##### Authorizing recipients on `SES`

Please note that at the time of writing all new mail domains
created in `SES` are put in **sandbox** mode. In order to send
mails, recipients *MUST* be verified from the `SES` console first
(after the `SES` domain has been provisioned).

See: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html

#### Rate limiting

In order to prevent abuse and unwanted charges, this application
enforces rate limiting on the `API Gateway` (used for `SendGrid`).
Check the [`terraform/api_gateway.tf`](terraform/api_gateway.tf)
file for details. Also, do not forget to set an
[`AWS Budget`](https://www.terraform.io/docs/providers/aws/r/api_gateway_account.html)
on your account to automatically monitor the costs.

## Technical notes

### `Lambda` function

#### Running tests

From the project root, run:

```
$ cd lambda
$ python -m unittest discover -s test
```

#### Limitations

Image attachments are extracted from the message body and passed to `Rekognition`
as a base64-encoded byte stream. Limits apply, see the
[official documentation](https://docs.aws.amazon.com/rekognition/latest/dg/limits.html#limits-image)
on the `AWS` website for details.

## Troubleshooting

### `SES` + `Route 53` Hosted Zone

The `SES` `domain` needs to be validated before it can be used. Validation is
achieved through a `DNS` record that *MUST* be set to a `SES`-provided value.
`SES` will read this record from the `domain` `DNS` records and validate it
to prove that you actually own the `domain`.
For this to work, the local `DNS` client *MUST* be able to read the `DNS`
records for the `domain` and look for the validation record.
If you have registered a domain in `Route 53` itself, this should work
out-of-the-box. If you have registered a `domain` with a third-party registrar,
after the `Hosted Zone` is created you will need to get the `NS` records values
for the `Hosted Zone` from `Route 53` and update them in your domain registrar's
configuration dashboard. It will possibly take some time for local `DNS` client
to get the updated `NS` records and be able to verify the `SES` `domain`.
In this case, if the `plan` fails (timing out) while you update the `NS` records
and wait for the update to be propagated, just re-apply the `plan` at a later
time and it will work.

### `Lambda` deployment

If `$ terraform apply` yields the following error:

```
Error: Error applying plan:

1 error(s) occurred:

* data.archive_file.lambda_release: data.archive_file.lambda_release: error archiving directory: could not archive missing directory: /{...}/../.deploy
```

the temporary `.zip` file containing the `Lambda` function code was deleted. The `Terraform` `plan` is
configured to package the `Lambda` function *if* it detects changes to the source code files. You can repackage
the `Lambda` function manually:

```
$ cd ../lambda
$ shovel package nozip
```

then re-apply the `plan`.

## References and credits

The following pages provided valuable documentation to build this project:

- https://anil.io/blog/aws/use-ses-lambda-mail-server-with-custom-domain-to-receive-emails/
- https://github.com/martysweet/aws-lambda-attachment-extractor
- https://github.com/alexbiship/lambda-ses-s3
- https://github.com/onnimonni/terraform-ses-lambda-demo
- https://github.com/cloudposse/terraform-aws-ses-lambda-forwarder
- https://learn.hashicorp.com/terraform/aws/lambda-api-gateway#configuring-api-gateway

