#Extract cert from .pfx with the key encrypted

#Extract cert
openssl pkcs12 -in input.pfx -clcerts -nokeys -out cert.pem

#Extract key
openssl pkcs12 -in input.pfx -nocerts -out encrypted.key

#Get thumbprint from cert
openssl pkcs12 -in $certfile -nokeys -out cert.pem;

openssl x509 -in cert.pem -fingerprint -noout -sha256