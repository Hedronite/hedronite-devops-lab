# Terraform + Terratest: Hello-World

One resource, one test. `main.tf` renders a single `local_file`; the Go test applies the module, reads the file back, asserts on its content, then destroys. This is the smallest complete loop of infrastructure-as-code with a test gate, and every larger terratest suite has this exact shape.

Copy the example into your workspace first. `/labs` and the repo checkout under it are read-only; Terraform needs to write state.

```bash
cp -r /workspace/hedronite-devops-lab/labs-examples/tf /workspace/tf-hello
```

Run the apply by hand once to see what the test automates:

```bash
cd /workspace/tf-hello
terraform init
terraform apply -auto-approve
cat hello.txt
terraform destroy -auto-approve
```

Then run it as a test. First run generates the module files:

```bash
cd /workspace/tf-hello/test
go mod init hello
go mod tidy
go test -v -timeout 10m
```

The test passes when `hello.txt` contains the greeting the test injected, which proves the whole chain: variables in, apply, output out, artifact on disk. Change the assertion string and watch it fail; a test you have never seen fail is not yet a test.
