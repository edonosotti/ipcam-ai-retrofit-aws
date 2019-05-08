resource "null_resource" "install_dependencies" {
  triggers {
    # To force the refresh of packages at every run,
    # uncomment the following line
    # uuid = "${uuid()}"
    requirements_dev = "${base64sha256(file("../lambda/requirements-dev.txt"))}"
  }

  provisioner "local-exec" {
    working_dir = "../lambda/"
    command = "pip install -r requirements-dev.txt"
  }
}

resource "null_resource" "prepare_release" {
  triggers {
    # To force the repackaging at every run,
    # uncomment the following line
    # uuid = "${uuid()}"
    main         = "${base64sha256(file("../lambda/main.py"))}"
    requirements = "${base64sha256(file("../lambda/requirements.txt"))}"
  }

  provisioner "local-exec" {
    working_dir = "../lambda/"
    command     = "shovel package nozip"
  }

  depends_on = ["null_resource.install_dependencies"]
}

data "archive_file" "lambda_release" {
  type        = "zip"
  source_dir  = "${path.module}/../.deploy"
  output_path = "${path.module}/../.deploy.zip"

  depends_on = ["null_resource.prepare_release"]
}

