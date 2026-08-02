package test

import (
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestHelloFile(t *testing.T) {
	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"greeting": "Hello from terratest",
		},
	})
	defer terraform.Destroy(t, opts)

	terraform.InitAndApply(t, opts)

	path := terraform.Output(t, opts, "hello_path")
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("reading %s: %v", path, err)
	}
	if !strings.Contains(string(data), "Hello from terratest") {
		t.Fatalf("unexpected content: %q", string(data))
	}
}
