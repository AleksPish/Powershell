#Extract cert from .pfx with the key encrypted

#Extract cert
openssl pkcs12 -in input.pfx -clcerts -nokeys -out cert.pem

#Extract key
openssl pkcs12 -in input.pfx -nocerts -out encrypted.key
