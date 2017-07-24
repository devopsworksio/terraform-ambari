## Terraform for Ambari

Playpen for me to experiment with AWS and ambari.

Builds 4 nodes, 3 for HDP centos 5.8 image and one for small ubuntu node for bootstrapping ansible.

Using spot instances to save $$$

### Provisioning

Ansible provisioner is simple rsync playbooks to ansible node, 
push private key, install ansible. Run manually at the moment while testing.

### Dynamic inventory   

I'm using ec2.py and identifying nodes by master / slave tags.

