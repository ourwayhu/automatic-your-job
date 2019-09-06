### azure use script create VM ###

# set subscription
az account set --subscription "DEMO-SUB"

# create resource group
az group create --name DEMO-SUB-JPW-GP --location "Japan West" 

# create virtual network
az network vnet create \
-g DEMO-SUB-JPW-GP \
-n DEMO-SUB-JPW-GP-vnet --address-prefix 10.1.0.0/24 \
--subnet-name default  \
--subnet-prefix 10.1.0.0/24

# create network security group
az network nsg create --resource-group DEMO-SUB-JPW-GP --name DEMO-SUB-JPW-GP_nsg

#Create an Availability set
az vm availability-set create --resource-group DEMO-SUB-JPW-GP --name jpw_as

# --------------------------------------------------------------------------
# Create an Azure Load Balancer.
az network lb create \
--resource-group DEMO-SUB-JPW-GP \
--name jpw_lb \
--frontend-ip-name LoadBalancerFrontEnd \
--backend-pool-name jpw-lb_pool \
--public-ip-address jpw-lb_ip \
--public-ip-address-allocation Static \
--sku Basic 

# Creates an LB probe 
for port in 80 443 8080 8443; do
  az network lb probe create \
  --resource-group DEMO-SUB-JPW-GP \
  --lb-name jpw_lb \
  --name probe-tcp-$port \
  --protocol tcp \
  --port $port
done


# Creates an LB rule 
for port in 80 443; do
  az network lb rule create \
  --resource-group DEMO-SUB-JPW-GP \
  --lb-name jpw_lb \
  --name http-$port-lb \
  --protocol tcp \
  --frontend-port $port \
  --backend-port $port \
  --frontend-ip-name LoadBalancerFrontEnd \
  --backend-pool-name jpw-lb_pool \
  --probe-name probe-tcp-$port
done


####################################################################
# create public-ip
az network public-ip create  \
--name jpw1\_ip \
--resource-group DEMO-SUB-JPW-GP \
--allocation-method Static \
--dns-name jpw1 \
--sku Basic 

# create NICs
az network nic create \
--resource-group DEMO-SUB-JPW-GP \
--name jpw1\_nic \
--subnet default \
--vnet-name DEMO-SUB-JPW-GP-vnet \
--network-security-group DEMO-SUB-JPW-GP_nsg \
--public-ip-address jpw1\_ip \
--private-ip-address 10.1.0.11 \
--lb-name jpw_lb \
--lb-address-pools jpw-lb_pool

# create VM
az vm create \
-g DEMO-SUB-JPW-GP \
-n jpw1 \
--image UbuntuLTS \
--size Standard_B1ms \
--availability-set jpw_as \
--nics jpw1\_nic \
--admin-username admin \
--authentication-type ssh \
--ssh-key-values " "

