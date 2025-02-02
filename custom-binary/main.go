package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("Enter any character: ")
	char, _ := reader.ReadByte()
	if char != 'z' {
		exitWithMessage("You did not enter the letter 'z'")
	}
	exitWithMessage("Goodbye!")
}

func exitWithMessage(message string) {
	fmt.Println(message)
	os.Exit(0)
}
