package main

import (
	"fmt"
	"os"
	"sort"
	"text/template"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/endpoints"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

func check(e error) {
	if e != nil {
		fmt.Println(e.Error())
		panic(e)
	}
}

// getRegions generates a list of AWS regions.
func getRegions() ([]string, error) {
	var output []string

	fmt.Println("Scanning for available AWS regions")

	sess, err := session.NewSession()
	check(err)

	ec2client := ec2.New(sess, aws.NewConfig().WithRegion(endpoints.UsEast1RegionID))
	resp, err := ec2client.DescribeRegions(&ec2.DescribeRegionsInput{})

	check(err)

	fmt.Println(resp)

	for _, r := range resp.Regions {

		if r != nil && r.RegionName != nil {
			fmt.Println("Found region", *r.RegionName)
			output = append(output, *r.RegionName)
		}
	}
	return output, nil
}

func main() {

	f, err := os.Create("regional.tf")
	check(err)
	defer f.Close()

	t, err := template.ParseFiles("regional.tf.template.gohtml")
	check(err)

	regions, err := getRegions()
	check(err)

	sort.Slice(regions,
		func(i, j int) bool {
			return regions[i] < regions[j]
		})

	err = t.Execute(f, regions)
	check(err)

}
