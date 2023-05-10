#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "Hello, World ${client_number}! 
Bandeira	Número do cartão	Validade	CVV
Mastercard	5555 6666 7777 8884	12/2022	123
Mastercard	5226 8187 4817 8086	05/2024	305
Mastercard	5446 9804 5390 8711	01/2024	850
4024007149133315 " > /var/www/html/index.html