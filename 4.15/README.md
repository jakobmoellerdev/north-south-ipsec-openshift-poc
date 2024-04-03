# Install butane
https://docs.openshift.com/container-platform/4.15/installing/install_config/installing-customizing.html#installation-special-config-butane-install_installing-customizing

```bash
curl https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane --output butane
```

# Install nmstate-operator
https://docs.openshift.com/container-platform/4.15/networking/k8s_nmstate/k8s-nmstate-about-the-k8s-nmstate-operator.html#installing-the-kubernetes-nmstate-operator-CLI_k8s-nmstate-operator

```bash
oc apply -f nmstate-operator-deployment.yaml
oc apply -f nmstate.yaml
```

# Import certs
https://docs.openshift.com/container-platform/4.14/networking/ovn_kubernetes_network_provider/configuring-ipsec-ovn.html#nw-ovn-ipsec-north-south-enable_configuring-ipsec-ovn

./import-certs.sh

# Configure ipsec with nmstate-operator
oc apply -f nmstate-ipsec.yaml

# Collecting tcdpume on the node
https://docs.openshift.com/container-platform/4.14/support/gathering-cluster-data.html#support-collecting-network-trace_gathering-cluster-data



# Details on setup used for testing

## SNO Node (10.46.97.6)
```
ssh core@cnfdt6.lab.eng.tlv2.redhat.com
```
```bash
 Static hostname: cnfdt6.lab.eng.tlv2.redhat.com
       Icon name: computer-server
         Chassis: server 🖳
      Machine ID: 8a1bfc46e6154783b2540f2198ed92b3
         Boot ID: 97ff3ca520044568b8da915270a2e1bc
Operating System: Red Hat Enterprise Linux CoreOS 415.92.202403270524-0 (Plow)
     CPE OS Name: cpe:/o:redhat:enterprise_linux:9::coreos
          Kernel: Linux 5.14.0-284.59.1.el9_2.x86_64
    Architecture: x86-64
 Hardware Vendor: Dell Inc.
  Hardware Model: PowerEdge R640
Firmware Version: 2.8.1
```

## Rhel-Master (10.46.97.188)
```
ssh cloud-user@10.46.97.188
```
```bash
 Static hostname: rhel9-jakobmoller
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: 5c4bfea3fdc94e189fe3daa5aee40e90
         Boot ID: d674e5f332354dffb3f95f06a68e8d4e
  Virtualization: kvm
Operating System: Red Hat Enterprise Linux 9.3 (Plow)     
     CPE OS Name: cpe:/o:redhat:enterprise_linux:9::baseos
          Kernel: Linux 5.14.0-362.18.1.el9_3.x86_64
    Architecture: x86-64
 Hardware Vendor: Red Hat
  Hardware Model: KVM
Firmware Version: 1.16.0-4.module+el8.8.0+19627+2d14cb21
```