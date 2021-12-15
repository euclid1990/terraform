output "web_server_url" {
  description = "Web Server URL"
  value       = join("", ["http://", aws_instance.my-instance.public_ip])
}

output "created_time" {
  description = "Date/Time of Execution"
  value       = timestamp()
}
