output "control_key" {
    description = "Location of the SSH key to access instances"
    value = "${var.control_key_path}"
}

output "web_ips" {
    description = "List of IP addresses to web instances."
    value = "${aws_instance.web.*.public_ip}"
}

output "address" {
    description = "Hostname of the load balancer to access websites."
    value = "${aws_elb.web.dns_name}"
}
