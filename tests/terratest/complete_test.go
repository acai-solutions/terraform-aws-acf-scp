package test

import (
	"os/exec"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSCP(t *testing.T) {
	t.Log("Ensuring boto3 is installed...")
	cmd := exec.Command("bash", "-c", "pip3 show boto3 || pip3 install boto3")
	err := cmd.Run()
	if err != nil {
		t.Fatalf("Failed to ensure boto3 is installed: %v", err)
	}

	t.Log("Starting ACF AWS SCP Module test")

	terraformDir := "../../examples/complete"
	stateKey := "terratest/terraform-aws-acf-scp.tfstate"
	backendConfig := loadBackendConfig(t, stateKey)

	// Create IAM Role
	terraformPreparation := &terraform.Options{
		TerraformBinary: getHclBinary(),
		TerraformDir: terraformDir,
		NoColor:      false,
		Lock:         true,
		Targets: []string{
			"module.create_provisioner",
			"module.ou_structure",
		},
		BackendConfig: backendConfig,
		Reconfigure:   true,
	}
	defer terraform.Destroy(t, terraformPreparation)
	terraform.InitAndApply(t, terraformPreparation)

	terraformModule := &terraform.Options{
		TerraformBinary: getHclBinary(),
		TerraformDir:  terraformDir,
		NoColor:       false,
		Lock:          true,
		BackendConfig: backendConfig,
		Reconfigure:   true,
	}
	defer terraform.Destroy(t, terraformModule)
	terraform.InitAndApply(t, terraformModule)

	// Retrieve the 'test_success' outputs (warnings stripped)
	testSuccessOutput := outputClean(t, terraformModule, "test_success")
	t.Logf("testSuccessOutput: %s", testSuccessOutput)

	// Assert that 'test_success' equals "true"
	assert.Equal(t, "true", testSuccessOutput, "The test_success output is not true")
}
