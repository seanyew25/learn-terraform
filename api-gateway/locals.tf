locals {
  books = jsondecode(file("data.json"))
}