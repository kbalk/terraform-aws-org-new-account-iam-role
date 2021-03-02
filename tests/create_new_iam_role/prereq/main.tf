resource "random_string" "id" {
  length  = 13
  special = false
}

output "random_string" {
  value = random_string.id
}
