package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/codepipeline"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAwsCodePipeline(t *testing.T) {
	t.Parallel()

	terraformDir := "../terraform" // ✅ Change path if your Terraform is elsewhere

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	pipelineName := terraform.Output(t, terraformOptions, "codepipeline_name")
	awsRegion := terraform.Output(t, terraformOptions, "aws_region")
	ec2PublicIp := terraform.Output(t, terraformOptions, "ec2_public_ip")

	sess, err := session.NewSession(&aws.Config{Region: aws.String(awsRegion)})
	assert.NoError(t, err)
	cpClient := codepipeline.New(sess)

	_, err = cpClient.GetPipeline(&codepipeline.GetPipelineInput{
		Name: aws.String(pipelineName),
	})
	assert.NoError(t, err)

	_, err = cpClient.StartPipelineExecution(&codepipeline.StartPipelineExecutionInput{
		Name: aws.String(pipelineName),
	})
	assert.NoError(t, err)

	waitForPipelineSuccess(t, cpClient, pipelineName)

	url := fmt.Sprintf("http://%s", ec2PublicIp)
	http_helper.HttpGetWithRetry(t, url, nil, 200, "", 30, 10*time.Second)
}

func waitForPipelineSuccess(t *testing.T, cpClient *codepipeline.CodePipeline, pipelineName string) {
	for i := 0; i < 20; i++ {
		stateOutput, err := cpClient.GetPipelineState(&codepipeline.GetPipelineStateInput{
			Name: aws.String(pipelineName),
		})
		assert.NoError(t, err)

		allSucceeded := true
		for _, stage := range stateOutput.StageStates {
			if stage.LatestExecution == nil || *stage.LatestExecution.Status != "Succeeded" {
				allSucceeded = false
				break
			}
		}

		if allSucceeded {
			fmt.Println("✅ Pipeline succeeded.")
			return
		}
		time.Sleep(15 * time.Second)
	}
	t.Fatal("❌ CodePipeline did not succeed within time.")
}
