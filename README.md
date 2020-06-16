### Deploy
```
$ terraform init
$ terraform plan
$ terraform apply
```

### SSH connection
```
$ terraform output ssh_private_key > ../ssh/default.pem
$ chmod 0600 ../ssh/default.pem
$ ssh -i ../ssh/default.pem cloud-user@$(terraform output floating_ip_management)
```
