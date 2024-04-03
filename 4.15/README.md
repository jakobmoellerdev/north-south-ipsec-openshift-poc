# Step By Step Instructions for setting up IPsec CPU Performance Testing on OpenShift SNO Clusters

## Prerequisites

### Create a SNO Cluster on 4.15+ as well as a RHEL 9.3 Node

1. We will assume a RHEL Node was installed under `192.168.124.253`, and will be referred to as the `north` node.
2. We will assume an OCP SNO Node was installed under `192.168.124.37`, and will be referred to as the `south` node.

### Install butane

Butane will be used to create MachineConfiguration Objects containing encoded Certificate data for import into the SNO.

https://docs.openshift.com/container-platform/4.15/installing/install_config/installing-customizing.html#installation-special-config-butane-install_installing-customizing

```bash
curl https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane --output butane
```

### Install nmstate-operator on the SNO

NMState Operator will be used to setup the Tunnel and Interface Connection on the SNO Node.

https://docs.openshift.com/container-platform/4.15/networking/k8s_nmstate/k8s-nmstate-about-the-k8s-nmstate-operator.html#installing-the-kubernetes-nmstate-operator-CLI_k8s-nmstate-operator

```bash
oc apply -f nmstate-operator-deployment.yaml
```

Once the Operator has been installed the NMState CustomResource can be created which will initialize the actual operator.

```bash
oc apply -f nmstate.yaml
```

### Patch the OVN Configuration on the SNO

```bash
oc patch networks.operator.openshift.io cluster --type=merge \
    -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"ipsecConfig":{"mode": "External"}}}}}'
oc patch networks.operator.openshift.io cluster --type=merge \
    -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"gatewayConfig":{"routingViaHost": true}}}}}'
```

## Using Butane to import Certificates into the SNO

To setup the SNO with the necessary certificates for IPsec, we will use Butane to create a MachineConfiguration Object containing the necessary data. 

### (Optional) Creating new Certificates

Note that this is only necessary if you want to create new certificates. If you already have certificates, you can skip this step. You can also use the existing certificates from the repository.

```bash
sh 9999-ipsec-new-cert-gen.sh
```

### Creating the MachineConfiguration and Applying it

```bash
sh 99-master-ipsec-certs.sh
```

This will generate a file called `99-master-ipsec-certs.yaml` which will contain the encoded certificates.

Now we can simply apply the generated MachineConfiguration, which will trigger a restart of the node:

```bash
oc apply -f 99-master-ipsec-certs.yaml
```

## Setting up the RHEL Node

### Install libreswan on the RHEL node

Libreswan is gonna be used to setup the VPN tunnel on the RHEL node.

```bash
sudo dnf install libreswan
```

### Configure the Tunnel Subnet for routing Traffic on the RHEL Node

Since we will need a dedicated subnet for the tunnel, we will create a new network interface for the tunnel.

```bash
sudo nmcli con add con-name ipsec ifname ipsec type tun mode tun
sudo nmcli con modify ipsec ipv4.addresses 172.16.110.8/24
sudo nmcli con modify ipsec ipv4.method manual
sudo nmcli con modify ipsec ipv6.method disabled
sudo nmcli conn up ipsec
```

This will create a new tunnel which will assign the subnet `172.16.110.0/24` to a new connection called `ipsec`.
Also, we will hardcode the interface address `172.16.110.8/24` so that we can easily communicate between the SNO
and the RHEL node without introducing a gateway routing.

### Configure the RHEL Certificates on the RHEL Node

Similar to the SNO, we will need to import the certificates into the RHEL node.

```bash
NSSDIR="/var/lib/ipsec/nss"
[ ! -f /etc/ipsec.d/cert9.db ] && ipsec initnss --nssdir ${NSSDIR} || echo
certutil -A -i ./ipsec-test-ca/ipsec-test-ca.crt -n "ipsec-test-ca" -t "CT,," -d sql:${NSSDIR} # /etc/ipsec.d is the location of the nss db, you should use the default showing when running ipsec initnss --help
# this assumes the current node is north, the other node is south
certutil -A -i ./ipsec-test-ca/south.crt -n "south" -t "P,," -d sql:${NSSDIR}
pk12util -i./ipsec-test-ca/north.p12 -d sql:${NSSDIR} -W ""
```

This will initialize the ipsec certificate store and import the certificates on the RHEL node.


### Configure the IPSec Connection on the RHEL Node

```bash
cat > "/etc/ipsec.d/sno.conf" <<-EOF
conn sno
    left=192.168.124.253
    leftid=%fromcert
    leftrsasigkey=%cert
    leftsubnet=172.16.110.0/24
    leftcert=north
    rightrsasigkey=%cert
    right=192.168.124.37
    rightid=%fromcert
    authby=rsasig
    auto=add
    rekey=no
    ikelifetime=86400s
    salifetime=3600s
    ikev2=insist
    phase2=esp
    fragmentation=yes
    ike=aes256-sha1
    phase2alg=aes256-sha1
EOF
sudo systemctl enable ipsec
sudo systemctl start ipsec
sudo ipsec auto --add sno
```

## Setting up the SNO

### Configure the IPSec Connection on the SNO

```bash
oc apply -f 100-nodenetworkconfigurationpolicy.yaml
```

### Verifying the Connection

You can now verify the connection by pinging the RHEL node from the SNO node once the Policy was applied.

```bash
oc debug node/sno-0
# In the SNO
ping 172.16.110.8
```

When the tunnel was successfully established, you should see the ping responses from the RHEL node.

## Setting up Performance Test Tooling

### Setup the Performance Profile

To simulate that the IPSec Tunnel workload should only be used on the management coreset, 
we will create a Performance Profile that will be used to pin the workload to the correct core.

```bash
# oc adm must-gather
# podman run --entrypoint performance-profile-creator -v ./must-gather.local.foobar:/must-gather:z registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v4.15 --mcp-name=master --reserved-cpu-count=2 --rt-kernel=true --split-reserved-cpus-across-numa=false --must-gather-dir-path /must-gather --power-consumption-mode=ultra-low-latency > performance-profile.yaml
cat <<EOF | oc apply -f -
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: ns-low-latency
spec:
  cpu:
    # Change the configuration here based on your core layout
    isolated: 2-7
    reserved: 0-1
  machineConfigPoolSelector:
    pools.operator.machineconfiguration.openshift.io/master: ""
  nodeSelector:
    node-role.kubernetes.io/master: ""
  numa:
    topologyPolicy: restricted
  realTimeKernel:
    enabled: true
  workloadHints:
    highPowerConsumption: false
    perPodPowerManagement: false
    realTime: true
EOF
```

The reserved CPU count in this example is using 2 threads on a hyperthreaded CPU, so it will reserve 1 core for the management core set.

Note that this will require a reboot.

### Prepare QOS Blocker Workload

To block IRQ kernel offloading to the isolated cores, we should add a workload scheduling 
a QOS blocker no-op workload that is using the runtime class"

```yaml
oc apply -f qos-blockers.yaml
```

To ensure that the QOS block has been achieved, you can check the pods `.status.qosClass` field which should be `Guaranteed`.

### Prepare the Performance Test on the SNO

Download and install the Prometheus Exporter for iperf3:

```bash
git clone https://github.com/Avielyo10/prom
cd prom 
pip install -e .
```

After that use it to deploy it to the cluster.

You will want to edit the config map to point to the correct iperf process id:

```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: process-exporter
  namespace: openshift-monitoring
data:
  config.yml: |
    process_names:
      - comm:
        - systemd
        cmdline:
        - --system
      - ppid: 1
      - comm:
        - iperf3
```

### Prepare the Performance Test on the RHEL Node

The next step involves creating a privileged deployment that will start the performance test.

```
sudo dnf install podman
podman run --network=host -it --rm quay.io/jmoller/iperf3:static --server -p 5201
```

Of course you can also build the image yourself

## Running iperf3

When Running iperf 3 all one needs to do is adjust the deployment configuration in `200-privileged-host-pid-iperf.yaml`.
After that apply it with

```bash
oc apply -f 200-privileged-host-pid-iperf.yaml
```

At that moment, the server should receive connections through the tunnel.
Note that if you want to have comparison results for not connecting through IPSec, you can use the host IP 
address of the node instead of the routed subnet and it will use a non-ipsec connection.


## Extracting data from prometheus

With all the above setup and the tunnel being used by iperf3, you can now extract the data from prometheus with 
queries like the following (only examples, you will need to adjust them to your setup):

```
sum without(mode, container, endpoint, instance, job, namespace, pod, prometheus, service, cpu) (irate(node_cpu_seconds_total{mode="system", cpu!="0|52"}[15m])) / 102

quantile_over_time(0.99,sum (irate(namedprocess_namegroup_cpu_seconds_total{groupname="iperf3", mode="system"}[15m]))[15m:])

quantile_over_time(0.99,sum (irate(namedprocess_namegroup_cpu_seconds_total{groupname="iperf3", mode="user"}[15m]))[15m:])
```